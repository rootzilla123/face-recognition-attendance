'use client';
import { useEffect, useRef, useState } from 'react';
import * as THREE from 'three';

export default function ThreeDHero() {
  const wrapRef = useRef<HTMLDivElement>(null);
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const [statusText, setStatusText] = useState('SCANNING');
  const [statusColor, setStatusColor] = useState('text-blue-400');

  useEffect(() => {
    if (!wrapRef.current || !canvasRef.current) return;

    const wrap = wrapRef.current;
    const canvas = canvasRef.current;
    
    let W = wrap.offsetWidth;
    let H = wrap.offsetHeight;

    // ── Renderer ──────────────────────────────────────────────────────────────
    const renderer = new THREE.WebGLRenderer({ canvas, antialias: true, alpha: true });
    renderer.setSize(W, H);
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    renderer.setClearColor(0x000000, 0);

    const onResize = () => {
      W = wrap.offsetWidth; 
      H = wrap.offsetHeight;
      renderer.setSize(W, H);
      camera.aspect = W / H;
      camera.updateProjectionMatrix();
    };
    window.addEventListener('resize', onResize);

    // ── Scene & Camera ────────────────────────────────────────────────────────
    const scene  = new THREE.Scene();
    const camera = new THREE.PerspectiveCamera(60, W / H, 0.1, 100);
    camera.position.set(0, 0, 5);

    // ── Lights ────────────────────────────────────────────────────────────────
    scene.add(new THREE.AmbientLight(0x001133, 2));
    const pt1 = new THREE.PointLight(0x00bfff, 3, 10);
    pt1.position.set(0, 2, 4);
    scene.add(pt1);

    // ── Procedural Face Mesh ──────────────────────────────────────────────────
    // We create a modified sphere to resemble a stylized human head/face
    const faceGeo = new THREE.SphereGeometry(1.5, 32, 32);
    const pos = faceGeo.attributes.position;
    for (let i = 0; i < pos.count; i++) {
      const v = new THREE.Vector3().fromBufferAttribute(pos, i);
      // Flatten face front
      if (v.z > 0.5) v.z *= 0.8;
      // Chin extension
      if (v.y < -0.5 && v.z > 0) {
        v.y *= 1.2;
        v.z += (v.y + 0.5) * 0.2;
      }
      // Cheeks narrowing
      if (v.x < -0.8 || v.x > 0.8) {
        if (v.y < 0) v.x *= 0.9;
      }
      pos.setXYZ(i, v.x, v.y, v.z);
    }
    faceGeo.computeVertexNormals();

    const faceMat = new THREE.MeshBasicMaterial({
      color: 0x0033ff,
      wireframe: true,
      transparent: true,
      opacity: 0.15
    });
    const faceMesh = new THREE.Mesh(faceGeo, faceMat);
    scene.add(faceMesh);

    // Background solid face for occlusion
    const occludeMat = new THREE.MeshPhysicalMaterial({
      color: 0x00061e,
      roughness: 0.8,
      metalness: 0.2,
      transparent: true,
      opacity: 0.9
    });
    const occludeMesh = new THREE.Mesh(faceGeo, occludeMat);
    occludeMesh.scale.set(0.98, 0.98, 0.98);
    scene.add(occludeMesh);

    // ── 68 Landmark Dots (Approximation) ──────────────────────────────────────
    const landmarkPos = [];
    // Just distributing points across the front of the face to simulate the 68 points
    for(let i = 0; i < pos.count; i += 15) {
      const x = pos.getX(i);
      const y = pos.getY(i);
      const z = pos.getZ(i);
      if (z > 0.6) { // Only front face
        landmarkPos.push(x, y, z);
      }
    }
    const landmarksGeo = new THREE.BufferGeometry();
    landmarksGeo.setAttribute('position', new THREE.Float32BufferAttribute(landmarkPos, 3));
    const landmarksMat = new THREE.PointsMaterial({
      color: 0x00f5c4,
      size: 0.05,
      transparent: true,
      opacity: 0.8
    });
    const landmarksPoints = new THREE.Points(landmarksGeo, landmarksMat);
    scene.add(landmarksPoints);

    // ── Eye Targeting Triangles ───────────────────────────────────────────────
    const makeEyeTarget = (xOffset: number) => {
      const geo = new THREE.ConeGeometry(0.1, 0.2, 3);
      const mat = new THREE.MeshBasicMaterial({ color: 0xff0055, wireframe: true });
      const mesh = new THREE.Mesh(geo, mat);
      mesh.rotation.x = Math.PI / 2;
      mesh.position.set(xOffset, 0.3, 1.3);
      return mesh;
    };
    const leftEye = makeEyeTarget(-0.4);
    const rightEye = makeEyeTarget(0.4);
    scene.add(leftEye, rightEye);

    // ── Scanning Line ─────────────────────────────────────────────────────────
    const scanGeo = new THREE.PlaneGeometry(4, 0.02);
    const scanMat = new THREE.MeshBasicMaterial({
      color: 0x00f5c4,
      transparent: true,
      opacity: 0.8,
      side: THREE.DoubleSide,
      blending: THREE.AdditiveBlending
    });
    const scanLine = new THREE.Mesh(scanGeo, scanMat);
    scene.add(scanLine);

    // ── Interaction & Animation ───────────────────────────────────────────────
    let isDragging = false;
    let prevX = 0, prevY = 0;
    
    wrap.addEventListener('mousedown', (e) => {
      isDragging = true;
      prevX = e.clientX;
      prevY = e.clientY;
    });
    wrap.addEventListener('mouseup', () => isDragging = false);
    wrap.addEventListener('mouseleave', () => isDragging = false);
    wrap.addEventListener('mousemove', (e) => {
      if (!isDragging) return;
      const deltaX = e.clientX - prevX;
      const deltaY = e.clientY - prevY;
      faceMesh.rotation.y += deltaX * 0.01;
      faceMesh.rotation.x += deltaY * 0.01;
      occludeMesh.rotation.copy(faceMesh.rotation);
      landmarksPoints.rotation.copy(faceMesh.rotation);
      leftEye.rotation.y = faceMesh.rotation.y;
      rightEye.rotation.y = faceMesh.rotation.y;
      
      prevX = e.clientX;
      prevY = e.clientY;
    });

    let t = 0;
    let animationFrameId: number;

    const statuses = [
      { text: 'SCANNING...', color: 'text-blue-400' },
      { text: 'MAPPING LANDMARKS', color: 'text-purple-400' },
      { text: 'ANALYZING THREATS', color: 'text-orange-400' },
      { text: 'MATCH FOUND: AUTHORIZED', color: 'text-green-400' }
    ];
    let statusIndex = 0;
    
    const intervalIds = [
      setInterval(() => {
        statusIndex = (statusIndex + 1) % statuses.length;
        setStatusText(statuses[statusIndex].text);
        setStatusColor(statuses[statusIndex].color);
      }, 2500)
    ];

    function animate() {
      animationFrameId = requestAnimationFrame(animate);
      t += 0.02;

      // Scanline sweep
      scanLine.position.y = Math.sin(t) * 1.5;

      // Eye targets pulse
      const pulse = 1 + Math.sin(t * 8) * 0.2;
      leftEye.scale.setScalar(pulse);
      rightEye.scale.setScalar(pulse);
      
      // Points react to scanline
      const positions = landmarksGeo.attributes.position.array as Float32Array;
      for (let i = 0; i < positions.length; i += 3) {
        // Transform the point by the mesh's rotation to get global Y
        const v = new THREE.Vector3(positions[i], positions[i+1], positions[i+2]);
        v.applyEuler(faceMesh.rotation);
        
        // Change point size/glow if near scanline
        if (Math.abs(v.y - scanLine.position.y) < 0.2) {
          positions[i+2] += Math.sin(t * 10) * 0.005; // Jitter
        }
      }
      landmarksGeo.attributes.position.needsUpdate = true;

      if (!isDragging) {
        // Auto slow rotation
        const rotY = Math.sin(t * 0.2) * 0.3;
        const rotX = Math.cos(t * 0.3) * 0.1;
        faceMesh.rotation.y = rotY;
        faceMesh.rotation.x = rotX;
        occludeMesh.rotation.copy(faceMesh.rotation);
        landmarksPoints.rotation.copy(faceMesh.rotation);
        
        // Sync eye targets slightly
        leftEye.position.x = -0.4 + Math.sin(rotY) * 1.2;
        rightEye.position.x = 0.4 + Math.sin(rotY) * 1.2;
      }

      renderer.render(scene, camera);
    }

    animate();

    return () => {
      window.removeEventListener('resize', onResize);
      intervalIds.forEach(clearInterval);
      cancelAnimationFrame(animationFrameId);
      renderer.dispose();
      scene.clear();
    };
  }, []);

  return (
    <div ref={wrapRef} className="w-full h-full relative cursor-grab active:cursor-grabbing">
      <canvas ref={canvasRef} className="w-full h-full block touch-none" />
      
      {/* UI Overlay */}
      <div className="absolute top-4 right-4 glass-panel p-4 rounded-xl border border-white/10 w-64">
        <div className="flex justify-between items-center mb-2">
          <span className="text-xs text-gray-400 font-mono tracking-wider">SYSTEM STATUS</span>
          <div className="w-2 h-2 rounded-full bg-green-500 animate-pulse"></div>
        </div>
        <div className={`font-mono text-sm tracking-widest font-bold ${statusColor} transition-colors duration-300`}>
          {statusText}
        </div>
        
        <div className="mt-4 grid grid-cols-2 gap-2 opacity-70">
          <div className="text-[10px] text-gray-500 font-mono">LANDMARKS</div>
          <div className="text-[10px] text-cyan-400 font-mono text-right">68 PTS ACTIVE</div>
          <div className="text-[10px] text-gray-500 font-mono">CONFIDENCE</div>
          <div className="text-[10px] text-cyan-400 font-mono text-right animate-pulse">99.8%</div>
        </div>
      </div>
      
      <div className="absolute bottom-4 left-4 text-xs font-mono text-gray-500 opacity-60">
        [ DRAG TO ROTATE 3D MESH ]
      </div>
    </div>
  );
}
