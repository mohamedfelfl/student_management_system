import os
import glob
import re

def main():
    base_dir = r"c:\Users\moham\Desktop\student_management_system"
    pattern = os.path.join(base_dir, "lib", "features", "*", "screens", "*_screen.dart")
    
    files = glob.glob(pattern)
    
    for file_path in files:
        basename = os.path.basename(file_path)
        # e.g. admin_panel_screen.dart -> admin_panel
        screen_name = basename.replace('_screen.dart', '')
        
        dir_name = os.path.dirname(file_path) # e.g. screens
        new_dir = os.path.join(dir_name, screen_name)
        
        os.makedirs(new_dir, exist_ok=True)
        new_file_path = os.path.join(new_dir, basename)
        
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
            
        def replace_import(match):
            import_statement = match.group(1)
            quote = match.group(2)
            path = match.group(3)
            # if the path is relative (doesn't start with package: or dart:)
            if not path.startswith('package:') and not path.startswith('dart:'):
                return import_statement + quote + '../' + path + quote
            return match.group(0)

        # Regex to match: import 'path/to/file.dart';
        # group 1: import \s* 
        # group 2: ' or "
        # group 3: path
        content = re.sub(r"(import\s+)(['\"])(.*?)\2", replace_import, content)
        
        with open(new_file_path, 'w', encoding='utf-8') as f:
            f.write(content)
            
        os.remove(file_path)
        print(f"Moved {basename} -> {screen_name}/{basename}")

if __name__ == '__main__':
    main()
