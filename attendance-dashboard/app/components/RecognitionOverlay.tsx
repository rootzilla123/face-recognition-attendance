'use client';

import { useEffect, useState } from 'react';

interface Detection {
  x: number;
  y: number;
  width: number;
  height: number;
  student_id?: string;
  student_name?: string;
  confidence?: number;
}

interface RecognitionOverlayProps {
  detections: Detection[];
  imageWidth: number;
  imageHeight: number;
  autoHideDelay?: number;
}

export default function RecognitionOverlay({
  detections,
  imageWidth,
  imageHeight,
  autoHideDelay = 3000
}: RecognitionOverlayProps) {
  const [visibleDetections, setVisibleDetections] = useState<Detection[]>([]);

  useEffect(() => {
    if (detections.length > 0) {
      setVisibleDetections(detections);

      // Auto-hide after delay
      const timer = setTimeout(() => {
        setVisibleDetections([]);
      }, autoHideDelay);

      return () => clearTimeout(timer);
    }
  }, [detections, autoHideDelay]);

  if (visibleDetections.length === 0) {
    return null;
  }

  return (
    <div className="absolute inset-0 pointer-events-none">
      <svg
        width="100%"
        height="100%"
        viewBox={`0 0 ${imageWidth} ${imageHeight}`}
        preserveAspectRatio="none"
        className="absolute inset-0"
      >
        {visibleDetections.map((detection, index) => {
          const isRecognized = !!detection.student_name;
          const boxColor = isRecognized ? '#22c55e' : '#eab308'; // green-500 : yellow-500
          
          return (
            <g key={index}>
              {/* Bounding box */}
              <rect
                x={detection.x}
                y={detection.y}
                width={detection.width}
                height={detection.height}
                fill="none"
                stroke={boxColor}
                strokeWidth="3"
                className="animate-pulse"
              />
              
              {/* Label background */}
              {isRecognized && (
                <>
                  <rect
                    x={detection.x}
                    y={detection.y - 30}
                    width={detection.width}
                    height="28"
                    fill={boxColor}
                    opacity="0.9"
                  />
                  
                  {/* Student name */}
                  <text
                    x={detection.x + detection.width / 2}
                    y={detection.y - 10}
                    fill="white"
                    fontSize="14"
                    fontWeight="bold"
                    textAnchor="middle"
                  >
                    {detection.student_name}
                  </text>
                  
                  {/* Confidence percentage */}
                  {detection.confidence && (
                    <text
                      x={detection.x + detection.width / 2}
                      y={detection.y - 10}
                      fill="white"
                      fontSize="12"
                      textAnchor="middle"
                      dy="14"
                    >
                      {Math.round(detection.confidence * 100)}%
                    </text>
                  )}
                </>
              )}
              
              {/* Unknown face label */}
              {!isRecognized && (
                <>
                  <rect
                    x={detection.x}
                    y={detection.y - 25}
                    width={detection.width}
                    height="23"
                    fill={boxColor}
                    opacity="0.9"
                  />
                  <text
                    x={detection.x + detection.width / 2}
                    y={detection.y - 8}
                    fill="white"
                    fontSize="12"
                    fontWeight="bold"
                    textAnchor="middle"
                  >
                    Unknown
                  </text>
                </>
              )}
            </g>
          );
        })}
      </svg>
    </div>
  );
}
