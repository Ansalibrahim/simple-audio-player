package com.reactlibrary;

import android.Manifest;
import android.app.Activity;
import android.content.ContextWrapper;
import android.content.pm.PackageManager;
import android.media.AudioManager;
import android.media.MediaPlayer;
import android.net.Uri;
import android.os.Environment;

import androidx.annotation.Nullable;
import androidx.core.app.ActivityCompat;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.PermissionAwareActivity;
import com.facebook.react.modules.core.PermissionListener;
import com.facebook.react.modules.core.DeviceEventManagerModule;


import java.io.File;
import java.io.IOException;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.atomic.AtomicBoolean;

// WritableMap params = Arguments.createMap();

public class RNSimpleAudioPlayerModule extends ReactContextBaseJavaModule {

  private final ReactApplicationContext reactContext;
  private MediaPlayer mediaPlayer;
  private MediaObserver observer = null;
  private Thread thread = null;

  // status events
  private final String PREPARING = "RNS_AUDIO/PREPARING";
  private final String READY = "RNS_AUDIO/READY";
  private final String PLAYING = "RNS_AUDIO/PLAYING";
  private final String PAUSED = "RNS_AUDIO/PAUSED";
  private final String ERROR = "RNS_AUDIO/ERROR";
  private final String IDLE = "RNS_AUDIO/IDLE";

// buffering events
// private final String BUFFERING = @"RNS_AUDIO/BUFFERING";

  private final String STATUS_EVENT = "RNS_AUDIO/STATUS_EVENT";
  private final String POSITION_EVENT = "RNS_AUDIO/POSITION_EVENT";
// private final String BUFFERING_EVENT = @"RNS_AUDIO/BUFFERING_EVENT";


  public RNSimpleAudioPlayerModule(ReactApplicationContext reactContext) {
    super(reactContext);
    this.reactContext = reactContext;
  }

  @Override
  public String getName() {
    return "RNSimpleAudioPlayer";
  }

  @Override
  public Map<String, Object> getConstants() {
    final Map<String, Object> constants = new HashMap<>();
    final Map<String, Object> eventTypes = new HashMap<>();
    final Map<String, Object> statusTypes = new HashMap<>();

    eventTypes.put("STATUS_EVENT", STATUS_EVENT);
    eventTypes.put("POSITION_EVENT", POSITION_EVENT);
    constants.put("EVENT_TYPES", eventTypes);

    statusTypes.put("PREPARING", PREPARING);
    statusTypes.put("READY", READY);
    statusTypes.put("PLAYING", PLAYING);
    statusTypes.put("PAUSED", PAUSED);
    statusTypes.put("ERROR", ERROR);
    statusTypes.put("IDLE", IDLE);
    
    constants.put("STATUS", statusTypes);
    return constants;
  }

  @ReactMethod
  public void prepare(final String path, final Promise promise) {
    sendStatusEvents(PREPARING);
    final Activity currentActivity = getCurrentActivity();
    int readPermission = ActivityCompat.checkSelfPermission(currentActivity, Manifest.permission.READ_EXTERNAL_STORAGE);
    if (readPermission != PackageManager.PERMISSION_GRANTED) {
      String[] PERMISSIONS = {
              Manifest.permission.READ_EXTERNAL_STORAGE,
      };
      ((PermissionAwareActivity) currentActivity).requestPermissions(PERMISSIONS, 1, new PermissionListener() {
        @Override
        public boolean onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
          if (requestCode == 1) {
            int readPermission = ActivityCompat.checkSelfPermission(currentActivity, Manifest.permission.READ_EXTERNAL_STORAGE);
            if (readPermission != PackageManager.PERMISSION_GRANTED) {
              // user rejected permission request
              promise.reject("Error", "User rejected permission");
              sendStatusEvents(IDLE);
              return true;
            }
            // permissions available
            prepareMediaPlayer(path, promise);
            return true;
          }
          return true;
        }
      });
    } else {
      prepareMediaPlayer(path, promise);
    }
  }

  @ReactMethod
  public void play(final Promise promise) {
    try {
      if (mediaPlayer != null && !mediaPlayer.isPlaying()) {
//        mediaPlayer.start();
        runMedia();
        WritableMap response = Arguments.createMap();
        promise.resolve(response);
        sendStatusEvents(PLAYING);
      } else {
        promise.reject("Error", "Unable to play audio now.");
      }
    } catch (IllegalStateException e) {
      e.printStackTrace();
      promise.reject("Error", "cannot play audio now");
    }
  }

  @ReactMethod
  public void pause(final Promise promise) {
    try {
      if (mediaPlayer != null && mediaPlayer.isPlaying()) {
        mediaPlayer.pause();
        WritableMap response = Arguments.createMap();
        promise.resolve(response);
        sendStatusEvents(PAUSED);
      } else {
        promise.reject("Error", "Unable to play audio now.");
      }
    } catch (IllegalStateException e) {
      e.printStackTrace();
      promise.reject("Error", "cannot play audio now");
    }
  }

  @ReactMethod
  public void stop(final Promise promise) {
    try {
      if (mediaPlayer != null && mediaPlayer.isPlaying()) {
        mediaPlayer.stop();
        WritableMap response = Arguments.createMap();
        promise.resolve(response);
        sendStatusEvents(READY);
        if (thread != null) {
          observer.stop();
          thread.join();
        }
      } else {
        promise.reject("Error", "Unable to play audio now.");
      }
    } catch (IllegalStateException e) {
      e.printStackTrace();
      promise.reject("Error", "cannot play audio now");
    } catch (InterruptedException e) {
      e.printStackTrace();
      promise.reject("Error", "cannot play audio now");
    }
  }

  @ReactMethod
  public void restart(final Promise promise) {
    try {
      if (mediaPlayer != null && mediaPlayer.isPlaying()) {
        mediaPlayer.stop();
        mediaPlayer.start();
        sendStatusEvents(PLAYING);
      } else {
        promise.reject("Error", "Unable to play audio now.");
      }
    } catch (IllegalStateException e) {
      e.printStackTrace();
      promise.reject("Error", "cannot play audio now");
    }
  }

  @ReactMethod
  public void resume(final Promise promise) {
    try {
      if (mediaPlayer != null && !mediaPlayer.isPlaying()) {
        mediaPlayer.start();
        WritableMap response = Arguments.createMap();
        promise.resolve(response);
        sendStatusEvents(PLAYING);
      } else {
        promise.reject("Error", "Unable to play audio now.");
      }
    } catch (IllegalStateException e) {
      e.printStackTrace();
      promise.reject("Error", "cannot play audio now");
    }
  }

  @ReactMethod
  public void setVolume(float volume) {
    if (mediaPlayer != null) {
      mediaPlayer.setVolume(volume, volume);
    }
  }

  private void prepareMediaPlayer(String path, Promise promise) {
    WritableMap response = Arguments.createMap();
    try {
      if (path.startsWith("http")) {
        mediaPlayer = new MediaPlayer();
        mediaPlayer.setAudioStreamType(AudioManager.STREAM_MUSIC);
        mediaPlayer.setDataSource(path);
        mediaPlayer.prepare();
        promise.resolve(response);
        sendStatusEvents(READY);
      } else {
        Uri uri = getFileUri(path);
        mediaPlayer = new MediaPlayer();
        mediaPlayer.setDataSource(reactContext, uri);
        mediaPlayer.setDataSource(path);
        mediaPlayer.prepare();
        promise.resolve(response);
        sendStatusEvents(READY);
      }
    } catch (IOException e) {
      e.printStackTrace();
      promise.reject("Error", "File not found.");
      sendStatusEvents(IDLE);
    }
  }

  private Uri getFileUri(String path) {
    File file = null;
    String fileNameWithoutExt;
    String extPath;

    // Try finding file in app data directory
    extPath = new ContextWrapper(reactContext).getFilesDir() + "/" + path;
    file = new File(extPath);
    if (file.exists()) {
      return Uri.fromFile(file);
    }

    // Try finding file on sdcard
    extPath = Environment.getExternalStorageDirectory() + "/" + path;
    file = new File(extPath);
    if (file.exists()) {
      return Uri.fromFile(file);
    }

    // Try finding file by full path
    file = new File(path);
    if (file.exists()) {
      return Uri.fromFile(file);
    }

    // Try finding file in Android "raw" resources
    if (path.lastIndexOf('.') != -1) {
      fileNameWithoutExt = path.substring(0, path.lastIndexOf('.'));
    } else {
      fileNameWithoutExt = path;
    }

    int resId = reactContext.getResources().getIdentifier(fileNameWithoutExt,
            "raw", reactContext.getPackageName());
    if (resId != 0) {
      return Uri.parse("android.resource://" + reactContext.getPackageName() + "/" + resId);
    }

    // Otherwise pass whole path string as URI and hope for the best
    return Uri.parse(path);
  }

  private void sendStatusEvents(String status) {
    WritableMap params = Arguments.createMap();
    params.putString("event", "status");
    params.putString("status", status);
    sendEvent(params);
  }

  private void sendPositionEvents(int progress) {
    WritableMap params = Arguments.createMap();
    params.putString("event", "status");
    params.putString("status", progress + "");
    sendEvent(params);
  }

  private void sendEvent(WritableMap params) {
    reactContext
            .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
            .emit("RNSAudio", params);
  }

  private class MediaObserver implements Runnable {
    private AtomicBoolean stop = new AtomicBoolean(false);

    public void stop() {
      stop.set(true);
    }

    @Override
    public void run() {
      while (!stop.get()) {
        if(mediaPlayer != null) {
          sendPositionEvents(mediaPlayer.getCurrentPosition());
          try {
            Thread.sleep(500);
          } catch (InterruptedException e) {
            e.printStackTrace();
          }
        }
      }
    }
  }

  public void runMedia() {
    mediaPlayer.setOnCompletionListener(new MediaPlayer.OnCompletionListener(){
      @Override
      public void onCompletion(MediaPlayer mPlayer) {
        observer.stop();
        sendPositionEvents(mPlayer.getCurrentPosition());
        sendStatusEvents(IDLE);
      }
    });
    observer = new MediaObserver();
    mediaPlayer.start();
    thread = new Thread(observer);
    thread.start();
  }

}
