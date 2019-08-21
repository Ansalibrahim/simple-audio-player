
# react-native-simple-audio-player

## Getting started

`$ npm install react-native-simple-audio-player --save`

### Mostly automatic installation

`$ react-native link react-native-simple-audio-player`

### Manual installation


#### iOS

1. In XCode, in the project navigator, right click `Libraries` ➜ `Add Files to [your project's name]`
2. Go to `node_modules` ➜ `react-native-simple-audio-player` and add `RNSimpleAudioPlayer.xcodeproj`
3. In XCode, in the project navigator, select your project. Add `libRNSimpleAudioPlayer.a` to your project's `Build Phases` ➜ `Link Binary With Libraries`
4. Run your project (`Cmd+R`)<

#### Android

1. Open up `android/app/src/main/java/[...]/MainActivity.java`
  - Add `import com.reactlibrary.RNSimpleAudioPlayerPackage;` to the imports at the top of the file
  - Add `new RNSimpleAudioPlayerPackage()` to the list returned by the `getPackages()` method
2. Append the following lines to `android/settings.gradle`:
  	```
  	include ':react-native-simple-audio-player'
  	project(':react-native-simple-audio-player').projectDir = new File(rootProject.projectDir, 	'../node_modules/react-native-simple-audio-player/android')
  	```
3. Insert the following lines inside the dependencies block in `android/app/build.gradle`:
  	```
      compile project(':react-native-simple-audio-player')
  	```

#### Windows
[Read it! :D](https://github.com/ReactWindows/react-native)

1. In Visual Studio add the `RNSimpleAudioPlayer.sln` in `node_modules/react-native-simple-audio-player/windows/RNSimpleAudioPlayer.sln` folder to their solution, reference from their app.
2. Open up your `MainPage.cs` app
  - Add `using Simple.Audio.Player.RNSimpleAudioPlayer;` to the usings at the top of the file
  - Add `new RNSimpleAudioPlayerPackage()` to the `List<IReactPackage>` returned by the `Packages` method


## Usage
```javascript
import RNSimpleAudioPlayer from 'react-native-simple-audio-player';

// TODO: What to do with the module?
RNSimpleAudioPlayer;
```
  