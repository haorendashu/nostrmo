package com.github.haorendashu.nostrmo;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Random;
import java.util.Set;

import android.app.Activity;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;

import androidx.annotation.NonNull;
import androidx.activity.ComponentActivity;
import androidx.activity.result.ActivityResult;
import androidx.activity.result.ActivityResultCaller;
import androidx.activity.result.ActivityResultCallback;
import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.contract.ActivityResultContract;
import androidx.activity.result.contract.ActivityResultContracts;

import io.flutter.Log;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

public class NostrmoPlugin implements FlutterPlugin, MethodCallHandler {

    private ComponentActivity activity;

    private MethodChannel channel;

    Map<String, Result> resultMap = new HashMap<>();

    NostrmoPlugin(ComponentActivity activity) {
        this.activity = activity;
        registeCallback();
    }

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "nostrmoPlugin");
        channel.setMethodCallHandler(this);
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        if (call.method.equals("getPlatformVersion")) {
            result.success("Android " + android.os.Build.VERSION.RELEASE);
        } else if (call.method.equals("existAndroidNostrSigner")) {
            boolean existResult = existAndroidNostrSigner();
            result.success(existResult);
        } else if (call.method.equals("startActivityForResult")) {
            Intent intent = new Intent();
            intent.setAction((String) call.argument("action"));
            if (call.argument("package") != null) {
                intent.setPackage((String) call.argument("package"));
            }
            if (call.argument("data") != null) {
                // Log.i("NostrmoPlugin", "reqeust data " + call.argument("data").toString());
                intent.setData(Uri.parse(call.argument("data")));
            }
            List flags = call.argument("flag");
            if (flags != null) {
                for (int i = 0; i < flags.size(); i++) {
                    Object flag = flags.get(i);
                    intent.addFlags((int) flag);
                }
            }
            List categorys = call.argument("category");
            if (categorys != null) {
                for (int i = 0; i < categorys.size(); i++) {
                    String category = (String) categorys.get(i);
                    intent.addCategory(category);
                }
            }
            if (call.argument("type") != null) {
                intent.setType((String) call.argument("type"));
            }

            Map<String, String> typeInfo = call.argument("typeInfo");
            Map<String, Object> extra = call.argument("extra");
            if (extra != null) {
                for (Map.Entry<String, Object> entry : extra.entrySet()) {
                    String key = entry.getKey();
                    Object value = entry.getValue();

                    // Log.i("NostrmoPlugin", "reqeust " + key + " " + value.toString());

                    if (typeInfo != null) {
                        String valueType = typeInfo.get(key);
                        switch (valueType) {
                            case "boolean": {
                                intent.putExtra(key, (boolean) value);
                                break;
                            }
                            case "byte":
                                intent.putExtra(key, (byte) value);
                                break;
                            case "short":
                                intent.putExtra(key, (short) value);
                                break;
                            case "int":
                                intent.putExtra(key, (int) value);
                                break;
                            case "long":
                                intent.putExtra(key, (long) value);
                                break;
                            case "float":
                                intent.putExtra(key, (float) value);
                                break;
                            case "double":
                                intent.putExtra(key, (double) value);
                                break;
                            case "char":
                                intent.putExtra(key, (char) value);
                                break;
                            case "String":
                                intent.putExtra(key, (String) value);
                                break;
                            case "boolean[]": {
                                List tmp = (List) value;
                                intent.putExtra(key, tmp.toArray(new Object[tmp.size()]));
                                break;
                            }
                            case "byte[]": {
                                List tmp = (List) value;
                                intent.putExtra(key, tmp.toArray(new Object[tmp.size()]));
                                break;
                            }
                            case "short[]": {
                                List tmp = (List) value;
                                intent.putExtra(key, tmp.toArray(new Object[tmp.size()]));
                                break;
                            }
                            case "int[]": {
                                List tmp = (List) value;
                                intent.putExtra(key, tmp.toArray(new Object[tmp.size()]));
                                break;
                            }
                            case "long[]": {
                                List tmp = (List) value;
                                intent.putExtra(key, tmp.toArray(new Object[tmp.size()]));
                                break;
                            }
                            case "float[]": {
                                List tmp = (List) value;
                                intent.putExtra(key, tmp.toArray(new Object[tmp.size()]));
                                break;
                            }
                            case "double[]": {
                                List tmp = (List) value;
                                intent.putExtra(key, tmp.toArray(new Object[tmp.size()]));
                                break;
                            }
                            case "char[]": {
                                List tmp = (List) value;
                                intent.putExtra(key, tmp.toArray(new Object[tmp.size()]));
                                break;
                            }
                            case "String[]": {
                                List tmp = (List) value;
                                intent.putExtra(key, tmp.toArray(new String[tmp.size()]));
                                break;
                            }
                            default:
                                intent.putExtra(key, (String) value);
                        }
                    }
                }
            }
            
            String id = System.currentTimeMillis() + "_" + (new Random().nextInt(1000));
            Object idObj = extra.get("id");
            if (idObj != null && idObj instanceof String) {
                id = (String) idObj;
            }
            intent.putExtra("id", id);
            resultMap.put(id, result);

            launcher.launch(intent);
        } else {
            result.notImplemented();
        }
    }

    ActivityResultLauncher launcher;

    void registeCallback() {
        launcher = activity.registerForActivityResult(new ActivityResultContracts.StartActivityForResult(),
        new ActivityResultCallback<ActivityResult>() {
            @Override
            public void onActivityResult(ActivityResult activityResult) {
                // Log.i("NostrmoPlugin", "onActivityResult");
                // Log.i("NostrmoPlugin", activityResult.getResultCode() + "");
                if (activityResult.getResultCode() == Activity.RESULT_OK) {
                    String id = activityResult.getData().getStringExtra("id");
                    if (id == null) {
                        return;
                    }
                    Result result = resultMap.remove(id);
                    if (result == null) {
                        return;
                    }

                    Map<String, Object> resultMap = new HashMap<String, Object>();
                    resultMap.put("resultCode", activityResult.getResultCode());

                    Intent resultIntent = activityResult.getData();
                    Map<String, Object> intentMap = new HashMap<String, Object>();
                    intentMap.put("action", resultIntent.getAction());
                    intentMap.put("package", resultIntent.getPackage());
                    intentMap.put("data", resultIntent.getDataString());
                    intentMap.put("flags", resultIntent.getFlags());
                    intentMap.put("categories", resultIntent.getCategories());
                    intentMap.put("type", resultIntent.getType());

                    Map<String, Object> extrasMap = new HashMap<String, Object>();
                    Set<String> keySet = resultIntent.getExtras().keySet();
                    for (String key : keySet) {
                        extrasMap.put(key, resultIntent.getExtras().get(key));
                        // Log.i("NostrmoPlugin", "response " + key + " " + resultIntent.getExtras().get(key).toString());
                    }
                    intentMap.put("extras", extrasMap);

                    resultMap.put("intent", intentMap);

                    result.success(resultMap);
                } else {
                    for (Map.Entry<String, Result> entry : resultMap.entrySet()) {
                        Result r = entry.getValue();
                        r.success(new HashMap<String, Object>());
                    }
                    resultMap.clear();
                }
            }
        });
    }

    boolean existAndroidNostrSigner() {
        Intent intent = new Intent(Intent.ACTION_VIEW, Uri.parse("nostrsigner:"));
        List infos = activity.getPackageManager().queryIntentActivities(intent, 0);
        if (infos.size() > 0) {
            return true;
        } else {
            return false;
        }
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
    }

}
