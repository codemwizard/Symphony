with open('example.html', 'r', encoding='utf-8') as f:
    example_text = f.read()

# We need to insert the navigation tab bar right below the .header.
tab_bar_html = """
<div class="tab-bar">
    <a class="tab active" href="programme-health.html" style="text-decoration:none;">Programme Health</a>
    <a class="tab" href="index.html#report" style="text-decoration:none;">Monitoring Report</a>
    <a class="tab risk-tab" href="index.html#onboarding" style="text-decoration:none;">OnboardingConsole</a>
    <a class="tab" href="index.html#s6" style="text-decoration:none;">Pilot Success</a>
</div>
"""

# Let's read example header and body structure.
# Notice example.html has inline CSS.
# In example.html, the <style> block has :root with --bg, --surface etc, which overlap with Symphony-redesign.md.
# The user wants "the theme and typesetting should be as in example.html".
# So using example.html's CSS + tab-bar is correct.

# Add tab-bar CSS to the style block
tab_bar_css = """
        /* ── TABS ── */
        .tab-bar {
            background: var(--surface);
            border-bottom: 1px solid var(--border);
            display: flex;
            padding: 0 28px;
            gap: 0;
        }
        .tab {
            font-family: var(--font-mono);
            font-size: 9px;
            letter-spacing: 0.2em;
            text-transform: uppercase;
            padding: 10px 18px;
            color: #8b949e;
            cursor: pointer;
            border-bottom: 2px solid transparent;
            transition: all 0.2s;
        }
        .tab:hover { color: var(--text); }
        .tab.active { color: var(--gold); border-bottom-color: var(--accent); }
        .tab.risk-tab.active { color: #f0a030; border-bottom-color: #d4821e; }
"""

# Insert tab_bar_css right before </style>
css_marker = "</style>"
css_pos = example_text.find(css_marker)
example_text = example_text[:css_pos] + tab_bar_css + example_text[css_pos:]

# Insert tab_bar_html right after <div class="header">...</div>
header_end = example_text.find('</div>\n\n<div class="kpi-ribbon">')
if header_end != -1:
    # the end of the header div is that first </div>
    example_text = example_text[:header_end + 6] + "\n" + tab_bar_html + example_text[header_end + 6:]

# Overwrite programme-health.html
with open('src/supervisory-dashboard/programme-health.html', 'w', encoding='utf-8') as f:
    f.write(example_text)

print("Rewritten programme-health.html")
