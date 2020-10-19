package com.innerwave.nice;

import android.util.Base64;

import java.security.Key;
import java.text.SimpleDateFormat;
import java.util.Date;

import javax.crypto.Cipher;
import javax.crypto.spec.SecretKeySpec;

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
