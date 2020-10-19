package com.innerwave.nice;

import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CallbackContext;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import android.widget.Toast;
import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.content.pm.PackageManager; 
import android.content.pm.PackageManager.NameNotFoundException;

/**
 * This class echoes a string called from JavaScript.
 */
public class NicePlugin extends CordovaPlugin {
    private final static String APPCARD_PKG = "com.nice.appcard";
    private final String noInstallMsg = "앱카드가 설치되어 있지 않습니다. 설치 페이지로 이동합니다.";
    //해당 패키지 명으로 검색하여 설치되어 있으면 true, 아니면 false를 리턴한다.
    private boolean isInstalledApplication() {
    	PackageManager pm = cordova.getActivity().getPackageManager();
    	try {
    	    pm.getApplicationInfo(APPCARD_PKG, PackageManager.GET_META_DATA);
    	} catch(NameNotFoundException e) {
    		e.printStackTrace(); 	
    		return false;
    	}
    	return true;
    }

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        if(!isInstalledApplication()){
          // 팝업 메시지로 "앱카드가 설치되어 있지 않습니다. 설치 페이지로 이동합니다." 안내 후
          // 구글플레이 다운로드 URL(market://details?id=com.nice.appcard)로 이동
          
          Context context=cordova.getActivity().getApplicationContext();
          Toast.makeText(context, noInstallMsg, Toast.LENGTH_SHORT).show();
          Intent intent = new Intent(Intent.ACTION_VIEW);
          intent.addCategory(Intent.CATEGORY_DEFAULT);
          intent.setData(Uri.parse("market://details?id=com.nice.appcard"));
          cordova.getActivity().startActivity(intent);

          return true;
        }else if (action.equals("callPayment")) {
            String message = args.getString(0);
            this.callPayment(message, callbackContext);
            return true;
        }
        return false;
    }

    private void callPayment(String message, CallbackContext callbackContext) {
        if (message != null && message.length() > 0) {
            callbackContext.success(message+" world");
        } else {
            callbackContext.error("Expected one non-empty string argument.");
        }
    }
}
