import {
  NativeModules,
  NativeEventEmitter,
  DeviceEventEmitter,
  Platform
} from "react-native";

class RNSAudioPlayer {
  constructor() {
    audioPlayer = NativeModules.RNSimpleAudioPlayer;
    emitter =
      Platform.OS === "ios"
        ? new NativeEventEmitter(audioPlayer)
        : DeviceEventEmitter;
    console.log("audioPlayer", audioPlayer);
  }

  prepare = url => {
    return audioPlayer.prepare(url);
  };

  addListener = cb => {
    emitter.addListener("RNSAudio", cb);
  };

  removeListener = cb => {
    emitter.removeListener("RNSAudio", cb);
  };

  play = () => {
    if (Platform.OS === "ios") return audioPlayer.play({});
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

RNSAudioPlayer.EVENT_TYPES = NativeModules.RNSimpleAudioPlayer.EVENT_TYPES;
RNSAudioPlayer.STATUS = NativeModules.RNSimpleAudioPlayer.STATUS;

export default RNSAudioPlayer;

