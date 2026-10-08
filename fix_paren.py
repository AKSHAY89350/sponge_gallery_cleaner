import sys

with open(r'lib/screens/blurry_photos_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Replace the LAST `));` with `);`
# Actually, let's just find the exact text block and replace it
target = """
      ),
    ));
  }
}"""
replacement = """
      ),
    );
  }
}"""

content = content.replace(target, replacement)

with open(r'lib/screens/blurry_photos_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Replaced parenthesis")
