import re

def process_programme_health():
    with open('src/supervisory-dashboard/programme-health.html', 'r', encoding='utf-8') as f:
        lines = f.readlines()

    out_lines = []
    in_screens = False
    skip_screen = False
    
    for i, line in enumerate(lines):
        # Update tab bar links
        if 'class="tab active" onclick="switchTab(\'main\', this)"' in line:
            line = line.replace('onclick="switchTab(\'main\', this)"', 'onclick="window.location.href=\'programme-health.html\'"')
            # Note: active stays on Programme Health
        elif 'onclick="switchTab(' in line and 'class="tab' in line:
            # For other tabs, redirect to index.html with a hash or just let them stay as is but add location.href
            match = re.search(r"switchTab\('([^']+)'", line)
            if match:
                tab_id = match.group(1)
                line = line.replace(f'onclick="switchTab(\'{tab_id}\', this)"', f'onclick="window.location.href=\'index.html#{tab_id}\';"')

        # Remove other screens
        if '<div class="screens">' in line:
            in_screens = True
            
        if in_screens:
            if '<div class="screen"' in line or '<div class="screen "' in line:
                if 'id="screen-main"' in line:
                    skip_screen = False
                else:
                    skip_screen = True
            
            if skip_screen and line.strip() == '</div>':
                # Might be end of screen or inner div
                pass
                
        out_lines.append(line)
        
    return out_lines

# Let's do it using BeautifulSoup if available, else plain python.
import html.parser
class ScreenParser(html.parser.HTMLParser):
    pass # Too complex to write robust parser manually like this.

