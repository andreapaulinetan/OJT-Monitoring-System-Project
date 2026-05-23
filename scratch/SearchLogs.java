package scratch;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;

public class SearchLogs {
    public static void main(String[] args) {
        File file = new File("C:\\Users\\andre\\.gemini\\antigravity\\brain\\775313d1-2915-4198-8142-4bd828b7f50a\\.system_generated\\logs\\transcript.jsonl");
        if (!file.exists()) {
            System.out.println("File does not exist");
            return;
        }
        try (BufferedReader br = new BufferedReader(new FileReader(file))) {
            String line;
            int lineNum = 0;
            while ((line = br.readLine()) != null) {
                lineNum++;
                if (lineNum == 264) {
                    System.out.println("Line 264 Full:");
                    System.out.println(line);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
