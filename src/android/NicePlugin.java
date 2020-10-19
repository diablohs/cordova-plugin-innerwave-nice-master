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
    private final String encryptKey = "영업 담당자를 통해 전달받은 암호키";
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
            cordova.setActivityResultCallback (this);

            String callStrEnc = "niceappcard://payment?partner_cd=%s"
            +"&partner_id=%s&merchant_cd=%s&pay_order=A&payPrice=%s&h=%s";
            String partner_cd = "NICE002";
            String partner_id = "";//NEncrypter.encryptString(encryptKey, "NICE002");
            String merchant_cd = NEncrypter.encryptString(encryptKey, "220811577001");
            String payPrice = "100";
            String h = "";//SHA-256(partner_cd + partner_id)

            callStrEnc = String.format(callStrEnc, partner_cd, partner_id, merchant_cd, payPrice, h);
            Intent intent = new Intent(Intent.ACTION_VIEW, Uri.parse(callStrEnc));
            cordova.startActivityForResult(this, intent, 100);            
        } else {
            callbackContext.error("Expected one non-empty string argument.");
        }
    }

    //응답 
    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if(resultCode == RESULT_OK && requestCode == 100){
            String otc = data.getStringExtra("OTC");
            String member_id = data.getStringExtra("MEMBER_ID");
            String card_comp_code = data.getStringExtra("CARD_COMP_CODE");
            String id_cd = data.getStringExtra("ID_CD");

            callbackContext.success(message+" world");
        }else{
            callbackContext.error("Error.");
        }
    }

    //암호화 
public class NEncrypter {

    public static String encryptString(String encKey, String originString){
 
       SimpleDateFormat sdf = new SimpleDateFormat("hhmmss");
       Date dd = new Date(System.currentTimeMillis());
       String systemTime = sdf.format(dd);
       String plainString = originString + systemTime; 
 
       StringBuffer keyStringBuffer = new StringBuffer();
       for (byte b : encKey.getBytes()) {
          keyStringBuffer.append(Integer.toString((b & 0xF0) >> 4, 16));
          keyStringBuffer.append(Integer.toString(b & 0x0F, 16));
       }
 
       try {
          Key key =  new SecretKeySpec(toBytes(keyStringBuffer.toString()), "AES");
          Cipher cipher = Cipher.getInstance("AES/ECB/PKCS5Padding");
          cipher.init(Cipher.ENCRYPT_MODE, key);
          byte[] plain = plainString.getBytes("UTF-8");
          byte[] encrypt = cipher.doFinal(plain);
          return new String(Base64.encode(encrypt, Base64.NO_WRAP));
       } catch (Exception e) {
          e.printStackTrace();
          return "";
       }
    }
 
    private static byte[] toBytes(String digits) throws IllegalArgumentException {
       int radix = 16;
       if (digits == null) {
          return null;
       }
 
       int divLen = 2;
 
       int length = digits.length();
       if (length % divLen == 1) {
          throw new IllegalArgumentException("For input string: \"" + digits + "\"");
       }
 
       length = length / divLen;
       byte[] bytes = new byte[length];
       for (int i = 0; i < length; i++) {
          int index = i * divLen;
          bytes[i] = (byte)(Short.parseShort(digits.substring(index, index+divLen), radix));
       }
       return bytes;
    } 
  }
}
