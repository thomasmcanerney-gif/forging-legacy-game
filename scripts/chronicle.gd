class_name Chronicle
extends RefCounted

var entries: Array[Dictionary] = []

func record(date_text: String, category: String, title: String, description: String) -> void:
	entries.append({
		"date": date_text,
		"category": category,
		"title": title,
		"description": description
	})

func get_display_text() -> String:
	if entries.is_empty():
		return "No deeds have yet been recorded."
	var lines: Array[String] = []
	for entry in entries:
		lines.append("%s  •  %s" % [String(entry.get("date", "")), String(entry.get("category", "")).to_upper()])
		lines.append(String(entry.get("title", "")))
		lines.append(String(entry.get("description", "")))
		lines.append("")
	return "\n".join(lines)
