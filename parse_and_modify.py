import re
import os

with open("src/supervisory-dashboard/programme-health.html", "r", encoding="utf-8") as f:
    text = f.read()

# 1. Add font links to head
font_link = '<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600;800&family=JetBrains+Mono&display=swap" rel="stylesheet">'
text = text.replace('<head>', '<head>\n  ' + font_link)

# 2. Update CSS vars
#   --serif: 'Playfair Display', serif;
#   --body: 'Crimson Pro', Georgia, serif;
text = text.replace("--serif: 'Playfair Display', serif;", "--serif: 'Inter', sans-serif;")
text = text.replace("--body: 'Crimson Pro', Georgia, serif;", "--body: 'Inter', sans-serif;")
# Also explicitly setting standard variables to Inter just in case
text = text.replace("font-family: var(--body)", "font-family: var(--body)")

# 3. Modify tab bar
# Make Programme Health a link to itself
text = text.replace('onclick="switchTab(\'main\', this)"', 'onclick="window.location.href=\'programme-health.html\'"')
# Modify others to link to index.html with hash
text = re.sub(r'onclick="switchTab\(\'([^main]+)\', this\)"', r'onclick="window.location.href=\'index.html#\1\'"', text)

# 4. Remove all screens except screen-main
screens_start = text.find('<div class="screens">')
if screens_start != -1:
    screen_main_start = text.find('<div class="screen visible" id="screen-main">', screens_start)
    screen_main_end = text.find('<div class="screen" id="screen-report">', screen_main_start)
    if screen_main_end == -1:
        screen_main_end = text.find('<div class="screen"', screen_main_start + 10)
    
    if screen_main_end != -1:
        # Keep everything before screen-main_end, and jump to <!-- /screens -->
        screens_end = text.find('</div><!-- /screens -->', screen_main_end)
        if screens_end != -1:
            text = text[:screen_main_end] + text[screens_end:]

# 5. Save programme-health.html
with open("src/supervisory-dashboard/programme-health.html", "w", encoding="utf-8") as f:
    f.write(text)


# Now modify index.html
with open("src/supervisory-dashboard/index.html", "r", encoding="utf-8") as f:
    idx_text = f.read()

# 1. Update tab navigation in index
# Programme Health should link out, others stay local SPA
idx_text = idx_text.replace('class="tab active" onclick="switchTab(\'main\', this)"', 'class="tab" onclick="window.location.href=\'programme-health.html\'"')
# We also want to auto-switch tab based on hash
hash_script = """
    // Hash routing for SPA
    window.addEventListener('DOMContentLoaded', () => {
        let hash = window.location.hash.replace('#', '');
        if (hash) {
            let tab = document.querySelector(`.tab[onclick*="switchTab('${hash}'"]`);
            if (tab) {
                switchTab(hash, tab);
            }
        }
    });
"""
idx_text = idx_text.replace('// ── TAB SWITCHING ──', hash_script + '\n    // ── TAB SWITCHING ──')

# 2. Remove screen-main markup from index.html (it's in programme-health now)
sm_start = idx_text.find('<div class="screen visible" id="screen-main">')
sm_end = idx_text.find('<div class="screen" id="screen-report">', sm_start)
if sm_start != -1 and sm_end != -1:
    idx_text = idx_text[:sm_start] + idx_text[sm_end:]

with open("src/supervisory-dashboard/index.html", "w", encoding="utf-8") as f:
    f.write(idx_text)

print("Modification complete")
