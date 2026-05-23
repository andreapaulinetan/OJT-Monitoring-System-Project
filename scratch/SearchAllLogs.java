package scratch;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;

public class SearchAllLogs {
    public static void main(String[] args) {
        File brainDir = new File("C:\\Users\\andre\\.gemini\\antigravity\\brain");
        traverse(brainDir);
    }

    private static void traverse(File file) {
        if (file.isDirectory()) {
            File[] files = file.listFiles();
            if (files != null) {
                for (File f : files) {
                    traverse(f);
                }
            }
        } else {
            if (file.getName().endsWith(".jsonl") || file.getName().endsWith(".txt") || file.getName().endsWith(".md")) {
                search(file);
            }
        }
    }

    private static void search(File file) {
        try (BufferedReader br = new BufferedReader(new FileReader(file))) {
            String line;
            int lineNum = 0;
            while ((line = br.readLine()) != null) {
                lineNum++;
                if (line.contains("dc80322dd14238969c8766559f9fb8bf650e78654215941d01cd7a39656e41c6") || 
                    line.contains("b31c2a7be37ef96288fa4086329ccb29d58de967943fe19b5ef5756bdcc79480")) {
                    System.out.println("Match in: " + file.getAbsolutePath() + " at line " + lineNum);
                    if (line.length() > 500) {
                        int idx = line.indexOf("dc80322d");
                        if (idx == -1) idx = line.indexOf("b31c2a7b");
                        int start = Math.max(0, idx - 100);
                        int end = Math.min(line.length(), idx + 300);
                        System.out.println("  Context: " + line.substring(start, end));
                    } else {
                        System.out.println("  Line: " + line);
                    }
                }
            }
        } catch (Exception e) {
            // ignore
        }
    }
}
