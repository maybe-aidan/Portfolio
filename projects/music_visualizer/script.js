import * as THREE from 'three';
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls.js';

const renderer = new THREE.WebGLRenderer({antialias: true});

renderer.setSize(window.innerWidth, window.innerHeight);

document.body.appendChild(renderer.domElement);

const scene = new THREE.Scene();

const camera = new THREE.PerspectiveCamera(
    45,
    window.innerWidth / window.innerHeight,
    0.1,
    1000
);

const orbit = new OrbitControls(camera, renderer.domElement)

camera.position.set(6, 8, 14);
orbit.update();

let playing = false;

const uniforms = {
    u_resolution: {type: "v2", value: new THREE.Vector2(window.innerWidth, window.innerHeight)},
    u_time: {value: 0.0},
    u_low: {value: 0.0},
    u_bass: {value: 0.0},
    u_mid: {value: 0.0},
    u_high: {value: 0.0},
    u_volume: {value: 0.0},
    u_hit: {value: 0.0}
}

const mat = new THREE.ShaderMaterial({
    wireframe: true,
    uniforms,
    vertexShader: document.getElementById('vertexshader').textContent,
    fragmentShader: document.getElementById('fragmentshader').textContent
});

const geo = new THREE.IcosahedronGeometry(4, 30);
const mesh = new THREE.Mesh(geo,mat);
scene.add(mesh)

const fileInput = document.getElementById('audio-upload');

const listener = new THREE.AudioListener();
camera.add(listener);

const sound = new THREE.Audio(listener);

if (sound.isPlaying) sound.stop();

const audioLoader = new THREE.AudioLoader();
const audioContext = listener.context;

let analyser;

fileInput.addEventListener('change', function() {
    if (sound.isPlaying) sound.stop();
    const file = this.files[0];
    if(!file) return;

    const reader = new FileReader();

    reader.onload = function(event) {
        const arrayBuffer = event.target.result;

        audioContext.decodeAudioData(arrayBuffer, function(buffer){
            sound.setBuffer(buffer);
            sound.setLoop(true);
            sound.setVolume(0.5);
            sound.play();

            analyser = new THREE.AudioAnalyser(sound, 512);
        })
    }

    reader.readAsArrayBuffer(file);
});

function getFrequencyRanges(frequencyData, sampleRate = 44100, fftSize = 512){
    const binFreq = i => i * (sampleRate/fftSize);

    const bands = {
        sub: [],
        bass:[],
        mid: [],
        high:[]
    };

    for (let i = 0; i < frequencyData.length; i++){
        const freq = binFreq(i);
        const val = frequencyData[i];

        if(freq < 60) bands.sub.push(val);
        else if(freq < 250) bands.bass.push(val);
        else if(freq < 2000) bands.mid.push(val);
        else bands.high.push(val);
    }

    /*
    const subBass = frequencyData.slice(1, 4)
    const bassRange = frequencyData.slice(4, 8);
    const midRange = frequencyData.slice(8, 32);
    const highRange = frequencyData.slice(32);
    */

    const avg = arr => arr.reduce((sum, val) => sum + val, 0) / arr.length;

    return {
        low: avg(bands.sub),
        bass: avg(bands.bass),
        mid: avg(bands.mid),
        high: avg(bands.high),
    }
}

let prevBass = 0;
let smoothedBass = 0;

const clock = new THREE.Clock();

let prevVolume = 0;
let smoothedVolume = 0;
let smoothedHit = 0;

function getPerceptualVolume(frequencyData) {
    let sum = 0;
    for (let i = 0; i < frequencyData.length; i++) {
        const freqNorm = i / frequencyData.length;
        const weight = Math.exp(-Math.pow((freqNorm - 0.25) * 3.5, 2)); // favor mids
        sum += frequencyData[i] * weight;
    }
    return sum / frequencyData.length / 255; // normalize 0–1
}

function animate(time){
    if(analyser){
        const frequencyData = analyser.getFrequencyData();
        const {low, bass, mid, high} = getFrequencyRanges(frequencyData);

        // Perceptual Volume
        const rawVolume = getPerceptualVolume(frequencyData);
        smoothedVolume = 0.9 * smoothedVolume + 0.1 * rawVolume;

        // Detect hits on volume spike
        const delta = Math.max(rawVolume - prevVolume, 0);
        smoothedHit = Math.max(smoothedHit * 0.9, delta * 10.0);
        prevVolume = rawVolume;
    
        // Normalize and detect kick
        const normBass = bass / 255.0;
        smoothedBass *= 0.95;
        smoothedBass = Math.min(Math.max(smoothedBass, (normBass - prevBass) * 7.0), 3.0);
        prevBass = normBass;
    
        uniforms.u_low.value = low / 255.0;
        uniforms.u_bass.value = normBass + smoothedBass;
        uniforms.u_mid.value = mid / 255.0;
        uniforms.u_high.value = high / 255.0;
        uniforms.u_volume.value = smoothedVolume;
        uniforms.u_hit.value = smoothedHit;
    }

    mesh.rotation.x = time / 5000.0;
    mesh.rotation.y = time / 10000.0;

    uniforms.u_time.value = clock.getElapsedTime();
    renderer.render(scene, camera);
}

renderer.setAnimationLoop(animate);

window.addEventListener('click', function(){
    playing = !playing;

    if(playing && analyser){
        sound.play();
    }else if(!playing && analyser){
        sound.pause();
    }
});

window.addEventListener('resize', function () {
    camera.aspect = window.innerWidth / window.innerHeight;
    camera.updateProjectionMatrix();
    renderer.setSize(window.innerWidth, window.innerHeight);
});