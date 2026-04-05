import os

dirs = ["Anthem", "Blaster", "Blue", "Ice", "Library", "Retro", "Revelant", "tech-support"]

for d in dirs:
    if os.path.isdir(d):
        for f in os.listdir(d):
            if f.endswith(".md") and f != "index.md":
                old_path = os.path.join(d, f)
                new_path = os.path.join(d, "index.md")
                with open(old_path, 'r', encoding='utf-8') as file:
                    content = file.read()
                
                if not content.startswith("---"):
                    content = "---\nlayout: default\n---\n\n" + content
                
                with open(new_path, 'w', encoding='utf-8') as str_file:
                    str_file.write(content)
                
                if old_path != new_path:
                    os.remove(old_path)
