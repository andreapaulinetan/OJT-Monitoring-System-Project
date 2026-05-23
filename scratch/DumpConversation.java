package scratch;

import java.io.BufferedReader;
import java.io.FileReader;

public class DumpConversation {
    public static void main(String[] args) {
        String logPath = "C:\\Users\\andre\\.gemini\\antigravity\\brain\\6dea2bca-bb3d-42e8-a7e8-6d848d614c7b\\.system_generated\\logs\\transcript.jsonl";
        try (BufferedReader br = new BufferedReader(new FileReader(logPath))) {
            String line;
            int stepNum = 0;
            while ((line = br.readLine()) != null) {
                stepNum++;
                // Check if it's user input or model output
                if (line.contains("\"type\":\"USER_INPUT\"") || line.contains("\"type\":\"PLANNER_RESPONSE\"")) {
                    // Let's find "content"
                    int contentIdx = line.indexOf("\"content\":\"");
                    if (contentIdx != -1) {
                        int endIdx = line.indexOf("\",\"", contentIdx + 11);
                        if (endIdx != -1) {
                            String content = line.substring(contentIdx + 11, endIdx);
                            // Replace escaped characters
                            content = content.replace("\\n", "\n").replace("\\\"", "\"").replace("\\\\", "\\");
                            if (content.toLowerCase().contains("70011") || content.toLowerCase().contains("password") || content.toLowerCase().contains("tan")) {
                                System.out.println("Step " + stepNum + ":");
                                System.out.println(content);
                                System.out.println("====================================================");
                            }
                        }
                    }
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
