with open("src/supervisory-dashboard/index.html", "r", encoding="utf-8") as f:
    text = f.read()

# Make Monitoring Report tab active by default
text = text.replace('class="tab" onclick="switchTab(\'report\', this)">Monitoring Report', 'class="tab active" onclick="switchTab(\'report\', this)">Monitoring Report')

# Make screen-report visible by default
text = text.replace('<div class="screen" id="screen-report">', '<div class="screen visible" id="screen-report">')

# But we might have also auto-switched if there is a hash. The script is:
# let hash = window.location.hash.replace('#', '');
# if (hash) { ... } else { switchTab('report', document.querySelector('.tab.active')); }
# Wait, actually just setting the classes is enough for default load without hash.

with open("src/supervisory-dashboard/index.html", "w", encoding="utf-8") as f:
    f.write(text)

print("fixed index.html")
