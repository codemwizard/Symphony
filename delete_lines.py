with open("src/supervisory-dashboard/index.html", "r", encoding="utf-8") as f:
    lines = f.readlines()

# Delete lines 1869 to 2847 (indices 1868 to 2846)
del lines[1868:2847]

with open("src/supervisory-dashboard/index.html", "w", encoding="utf-8") as f:
    f.writelines(lines)
