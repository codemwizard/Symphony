import re
with open('src/supervisory-dashboard/index.html', 'r') as f:
    text = f.read()
# Let's find what was in screen-main
import sys
# just print the JS bindings
matches = re.findall(r"document\.getElementById\('([^']+)'\)", text)
print("DOM IDs used in index.html JS:", set(matches))
