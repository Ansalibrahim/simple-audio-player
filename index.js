import {
  NativeModules,
  NativeEventEmitter,
  DeviceEventEmitter
} from "react-native";

function RNSAudioPlayer() {
  const audioPlayer = NativeModules.RNSimpleAudioPlayer;
  const emitter =
    Platform.OS === "ios"
      ? new NativeEventEmitter(audioPlayer)
      : DeviceEventEmitter;

  prepare = (url, options = {}, cb) => {
    return audioPlayer.prepare(url, options);
  };
  addListener = cb => {
    emitter.addListener("RNSAudio", cb);
  };
  removeListener = cb => {
    emitter.removeListener("RNSAudio", cb);
  };
  play = () => {
    return audioPlayer.play();
  };
  pause = () => {
    return audioPlayer.pause();
  };
  stop = () => {
    return audioPlayer.stop();
  };
  setVolume = newValue => {
    audioPlayer.setVolume(newValue);
  };
  restart = () => {};
}

export default RNSAudioPlayer;
