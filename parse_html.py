import re

with open('src/supervisory-dashboard/index.html', 'r', encoding='utf-8') as f:
    html = f.read()

# Let's find the navigation bar
nav_match = re.search(r'(<div class="tab-bar">.*?</div>)', html, re.DOTALL)
if nav_match:
    nav_html = nav_match.group(1)
    print("Nav HTML found")

# Find screen-main
screen_main = re.search(r'(<div class="screen visible" id="screen-main">.*?</div><!-- /screens -->)', html, re.DOTALL)
if screen_main:
    print("Screen Main found")

