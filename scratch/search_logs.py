import os
import json

brain_dir = r"C:\Users\andre\.gemini\antigravity\brain"

for root, dirs, files in os.walk(brain_dir):
    for file in files:
        if file == "transcript.jsonl":
            path = os.path.join(root, file)
            with open(path, 'r', encoding='utf-8', errors='ignore') as f:
                for line_num, line in enumerate(f, 1):
                    if "70011" in line or "andreapauline" in line:
                        print(f"File: {path}, Line: {line_num}")
                        try:
                            data = json.loads(line)
                            print(f"  Step Index: {data.get('step_index')}")
                            print(f"  Type: {data.get('type')}")
                            content = data.get('content', '')
                            if content:
                                print(f"  Content: {content[:300]}...")
                            tool_calls = data.get('tool_calls', [])
                            if tool_calls:
                                print(f"  Tool calls: {str(tool_calls)[:300]}...")
                        except Exception as e:
                            print(f"  Raw: {line[:300]}...")
                        print("-" * 50)
