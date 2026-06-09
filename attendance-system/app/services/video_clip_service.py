import cv2
import asyncio
from datetime import datetime, timedelta
from pathlib import Path
import logging
from collections import deque
from threading import Lock

logger = logging.getLogger(__name__)


class VideoClipService:
    """
    Captures rolling video clips around face recognition events.
    Maintains a per-camera ring buffer of recent frames (pre-detection),
    then captures live frames for the post-detection window.
    """

    def __init__(self, clips_dir="/var/attendance_clips", retention_days=7, fps=5, pre_seconds=5, post_seconds=5):
        self.clips_dir = Path(clips_dir)
        self.retention_days = retention_days
        self.fps = fps
        self.pre_seconds = pre_seconds
        self.post_seconds = post_seconds

        # camera_id (str|int) -> deque of {"frame": np.ndarray, "timestamp": datetime}
        self.frame_buffers: dict = {}
        self.buffer_lock = Lock()

        # camera_id -> VideoStreamManager reference (set by VideoStreamingService)
        self._stream_managers: dict = {}

    # ── Buffer management ────────────────────────────────────────────────────

    def init_camera_buffer(self, camera_id):
        """Create a rolling frame buffer for a camera (idempotent)."""
        key = str(camera_id)
        with self.buffer_lock:
            if key not in self.frame_buffers:
                max_frames = self.fps * self.pre_seconds
                self.frame_buffers[key] = deque(maxlen=max_frames)
                logger.info(f"Initialized clip buffer for camera {camera_id} ({max_frames} frames)")

    def add_frame(self, camera_id, frame):
        """Push a frame into the rolling pre-detection buffer."""
        key = str(camera_id)
        with self.buffer_lock:
            if key in self.frame_buffers:
                self.frame_buffers[key].append({
                    "frame": frame.copy(),
                    "timestamp": datetime.now(),
                })

    def register_stream_manager(self, camera_id, video_stream_manager):
        """Register the VideoStreamManager so we can pull live frames post-detection."""
        self._stream_managers[str(camera_id)] = video_stream_manager

    # ── Clip saving ──────────────────────────────────────────────────────────

    async def save_clip(self, camera_id, attendance_id: str, detection_frame) -> str | None:
        """
        Write a clip: pre_seconds of buffered frames + detection frame + post_seconds of live frames.
        Returns the saved file path, or None on failure.
        """
        try:
            date_dir = self.clips_dir / datetime.now().strftime("%Y-%m-%d")
            date_dir.mkdir(parents=True, exist_ok=True)
            clip_path = date_dir / f"{attendance_id}.mp4"

            # Snapshot the pre-detection buffer
            key = str(camera_id)
            with self.buffer_lock:
                pre_frames = [f["frame"] for f in self.frame_buffers.get(key, [])]

            height, width = detection_frame.shape[:2]
            fourcc = cv2.VideoWriter_fourcc(*"mp4v")
            out = cv2.VideoWriter(str(clip_path), fourcc, self.fps, (width, height))

            # Write pre-detection frames (may be empty if buffer not yet full)
            for f in pre_frames:
                out.write(f)

            # Write the detection frame itself
            out.write(detection_frame)

            # Capture live post-detection frames
            vsm = self._stream_managers.get(key)
            post_frame_count = self.fps * self.post_seconds
            captured = 0

            if vsm is not None:
                interval = 1.0 / self.fps
                for _ in range(post_frame_count):
                    await asyncio.sleep(interval)
                    success, live_frame = vsm.read_frame(key)
                    if success and live_frame is not None:
                        # Resize to match clip dimensions if needed
                        lh, lw = live_frame.shape[:2]
                        if (lw, lh) != (width, height):
                            live_frame = cv2.resize(live_frame, (width, height))
                        out.write(live_frame)
                        captured += 1
                    else:
                        out.write(detection_frame)  # fallback: repeat last known frame
            else:
                # No live stream available — pad with detection frame
                for _ in range(post_frame_count):
                    out.write(detection_frame)

            out.release()
            logger.info(
                f"Saved clip {clip_path} "
                f"(pre={len(pre_frames)}, post_live={captured}/{post_frame_count})"
            )
            return str(clip_path)

        except Exception as e:
            logger.error(f"Failed to save clip for attendance {attendance_id}: {e}")
            return None

    # ── Cleanup ──────────────────────────────────────────────────────────────

    async def cleanup_old_clips(self):
        """Delete clip directories older than retention_days."""
        try:
            cutoff = datetime.now() - timedelta(days=self.retention_days)
            deleted = 0
            if not self.clips_dir.exists():
                return
            for date_dir in self.clips_dir.iterdir():
                if not date_dir.is_dir():
                    continue
                try:
                    dir_date = datetime.strptime(date_dir.name, "%Y-%m-%d")
                    if dir_date < cutoff:
                        for clip in date_dir.glob("*.mp4"):
                            clip.unlink()
                            deleted += 1
                        date_dir.rmdir()
                        logger.info(f"Removed old clips dir: {date_dir}")
                except ValueError:
                    continue
            if deleted:
                logger.info(f"Clip cleanup: removed {deleted} old clips")
        except Exception as e:
            logger.error(f"Clip cleanup failed: {e}")

    async def cleanup_loop(self):
        """Background task — runs cleanup once per day."""
        while True:
            await asyncio.sleep(86400)
            await self.cleanup_old_clips()
