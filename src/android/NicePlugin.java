package com.innerwave.nice;

import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CallbackContext;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import android.util.Log;

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
    private CallbackContext callbackContext;
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
        this.callbackContext = callbackContext;
        if (message != null && message.length() > 0) {
            cordova.setActivityResultCallback (this);
            JSONObject json = null;

            try {
                json = new JSONObject(message);
            } catch (JSONException e) {
                e.printStackTrace();
                Log.e("NicePlugin", e.toString());
            }

            String callStrEnc = "niceappcard://payment?partner_cd=%s"
            +"&partner_id=%s&merchant_cd=%s&pay_order=A&payPrice=%s&h=%s";
            String partnerCd = json.getString("partnerCd");
            String partnerId = NEncrypter.encryptString(encryptKey, json.getString("partnerId"));
            String merchantCd = NEncrypter.encryptString(encryptKey, json.getString("merchantCd"));
            String payPrice = json.getString("payPrice");
            String h = NEncrypter.sha256(partnerCd + partnerId)

            callStrEnc = String.format(callStrEnc, partnerCd, partnerId, merchantCd, payPrice, h);
            Intent intent = new Intent(Intent.ACTION_VIEW, Uri.parse(callStrEnc));
            cordova.startActivityForResult(this, intent, 100);            
        } else {
            callbackContext.error("Expected one non-empty string argument.");
        }
    }

    //응답 
    @Override
    public void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        /*
        -1	success	성공
        0	사용자가 취소하였습니다.	정상 화면에서 사용자 취소
        400	파라미터 요청이 올바르지 않습니다.	필수 파라미터 오류.
        405	"네트워크 연결이 되지 않았습니다.
        잠시 후 다시 이용해 주세요."	네트워크 연결 실패
        801	카드 등록 실패하였습니다.	카드 등록 실패
        802	카드 삭제 실패하였습니다.	카드 삭제 실패
        803	PIN 입력 초과 오류입니다.	PIN 입력 초과 오류
        812	중계시스템 오류입니다.	"DB, 세션 등 중계시스템 오류
        개발 진행 상황에서 발생"
        813	루팅된 기기를 사용중입니다. 루팅된 기기로 앱을 실행할 수 없습니다.	루팅 디바이스
        815	악성코드가 발견 되었습니다	악성코드 발견시 
        201	앱 강제 업데이트를 실행하였습니다.	앱 업데이트 진행
        202	시스템 점검 중입니다.	시스템 점검
        */

        JSONObject json = new JSONObject();

        if(requestCode == 100){            
            String otc = data.getStringExtra("OTC");
            String memberId = data.getStringExtra("MEMBER_ID");
            String cardCompCode = data.getStringExtra("CARD_COMP_CODE");
            String idCd = data.getStringExtra("ID_CD");

            try {
                json.put("resultCode", resultCode);
                json.put("otc", otc);
                json.put("memberId", memberId);
                json.put("cardCompCode", cardCompCode);
                json.put("idCd", idCd);
            } catch (JSONException e) {
                e.printStackTrace();
                Log.e("NicePlugin", e.toString());
            }
            
            this.callbackContext.success(json.toString());
        }else{
            try {
                json.put("resultCode", resultCode);
            } catch (JSONException e) {
                e.printStackTrace();
                Log.e("NicePlugin", e.toString());
            }
            this.callbackContext.error(json.toString());
        }
    }
}
