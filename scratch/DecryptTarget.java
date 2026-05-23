package scratch;

import util.CryptoUtil;

public class DecryptTarget {
    public static void main(String[] args) {
        String[] ciphertexts = {
            "2OJkKZY2I09wf9fiC8Ag64qtWc+7e/dSnazY4nRQGF1D5cRFgZCGvCZ/GzJTyoV4kGWdyP72M3bDWzudhDJl7QUBh6DN5amHLLqwkatz5VM=",
            "AaUA1NpGe7xZX+a0sVFFW6wZL28KWnNlV02y8IbFLTpACWQHuT7rM2O3zgcjG/V1PiANwxsJXNkIiYzVBYnsIeaQA5nSTm+kG0ASr4suNcI="
        };
        for (int i = 0; i < ciphertexts.length; i++) {
            try {
                String decrypted = CryptoUtil.decrypt(ciphertexts[i]);
                System.out.println("DECRYPTED PASSWORD " + (i+1) + ": " + decrypted);
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }
}
