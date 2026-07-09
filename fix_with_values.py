import os
import re

def fix_with_values(directory):
    pattern = re.compile(r'\.withValues\(\s*alpha\s*:\s*([^)]+)\)')
    for root, _, files in os.walk(directory):
        for file in files:
            if file.endswith(".dart"):
                filepath = os.path.join(root, file)
                try:
                    with open(filepath, 'r', encoding='utf-8') as f:
                        content = f.read()
                    
                    new_content = pattern.sub(r'.withOpacity(\1)', content)
                    
                    if content != new_content:
                        with open(filepath, 'w', encoding='utf-8') as f:
                            f.write(new_content)
                        print(f"Updated withOpacity in: {filepath}")
                except Exception as e:
                    print(f"Error processing {filepath}: {e}")

if __name__ == "__main__":
    fix_with_values("/Users/cristhiancabrera/Desktop/socio/lib")
