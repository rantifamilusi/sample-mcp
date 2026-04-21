#!/usr/bin/env sh
set -eu

# Build and launch both services with Compose.
docker compose up --build --remove-orphans -d app app-dhi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

scan_image() {
	image="$1"
	out_file="$2"

	echo "Scanning $image ..."
	docker scout cves "$image" > "$out_file" 2>&1
	echo
	echo "--- Docker Scout Raw Output: $image ---"
	cat "$out_file"
	echo "--- End Docker Scout Raw Output: $image ---"
}

extract_count() {
	severity="$1"
	line="$2"
	# Parse tokens like "3H", "25L", "0C" from the vulnerabilities summary line.
	echo "$line" | awk -v s="$severity" '{
		for (i = 1; i <= NF; i++) {
			if ($i ~ "^[0-9]+" s "$") {
				gsub(s "$", "", $i)
				print $i
				exit
			}
		}
		print 0
	}'
}

severity_count_from_findings() {
	severity="$1"
	file="$2"
	awk -v sev="$severity" '$0 ~ "✗[[:space:]]+" sev { c++ } END { print c + 0 }' "$file"
}

summary_line() {
	file="$1"
	awk '/vulnerabilities \|/ { line=$0 } END { print line }' "$file"
}

detected_packages() {
	file="$1"
	awk '/Detected [0-9]+ vulnerable package/ {
		for (i = 1; i <= NF; i++) {
			if ($i ~ /^[0-9]+$/) {
				print $i
				exit
			}
		}
	}' "$file"
}

detected_vulns() {
	file="$1"
	awk '/Detected [0-9]+ vulnerable package/ {
		for (i = 1; i <= NF; i++) {
			if ($i == "with" && (i+1) <= NF && $(i+1) ~ /^[0-9]+$/) {
				print $(i+1)
				exit
			}
		}
	}' "$file"
}

print_table() {
	app_file="$1"
	dhi_file="$2"

	app_line="$(summary_line "$app_file")"
	dhi_line="$(summary_line "$dhi_file")"

	app_pkg="$(detected_packages "$app_file")"
	app_total="$(detected_vulns "$app_file")"
	dhi_pkg="$(detected_packages "$dhi_file")"
	dhi_total="$(detected_vulns "$dhi_file")"

	app_pkg="${app_pkg:-0}"
	app_total="${app_total:-0}"
	dhi_pkg="${dhi_pkg:-0}"
	dhi_total="${dhi_total:-0}"

	if [ -n "$app_line" ]; then
		app_c="$(extract_count C "$app_line")"
		app_h="$(extract_count H "$app_line")"
		app_m="$(extract_count M "$app_line")"
		app_l="$(extract_count L "$app_line")"
		app_u="$(extract_count '?' "$app_line")"
	else
		app_c="$(severity_count_from_findings CRITICAL "$app_file")"
		app_h="$(severity_count_from_findings HIGH "$app_file")"
		app_m="$(severity_count_from_findings MEDIUM "$app_file")"
		app_l="$(severity_count_from_findings LOW "$app_file")"
		app_u=0
	fi

	if [ -n "$dhi_line" ]; then
		dhi_c="$(extract_count C "$dhi_line")"
		dhi_h="$(extract_count H "$dhi_line")"
		dhi_m="$(extract_count M "$dhi_line")"
		dhi_l="$(extract_count L "$dhi_line")"
		dhi_u="$(extract_count '?' "$dhi_line")"
	else
		dhi_c="$(severity_count_from_findings CRITICAL "$dhi_file")"
		dhi_h="$(severity_count_from_findings HIGH "$dhi_file")"
		dhi_m="$(severity_count_from_findings MEDIUM "$dhi_file")"
		dhi_l="$(severity_count_from_findings LOW "$dhi_file")"
		dhi_u=0
	fi

	print_sep() {
		printf '+-----------------------+----------------------+-----------------------+----------+----------+----------+----------+----------+\n'
	}

	echo
	echo "Vulnerability Comparison"
	print_sep
	printf '| %-21s | %20s | %21s | %8s | %8s | %8s | %8s | %8s |\n' \
		"Image" "Vulnerable Packages" "Total Vulnerabilities" "Critical" "High" "Medium" "Low" "Unknown"
	print_sep
	printf '| %-21s | %20s | %21s | %8s | %8s | %8s | %8s | %8s |\n' \
		"sample-mcp:latest" "$app_pkg" "$app_total" "$app_c" "$app_h" "$app_m" "$app_l" "$app_u"
	printf '| %-21s | %20s | %21s | %8s | %8s | %8s | %8s | %8s |\n' \
		"sample-mcp-dhi:latest" "$dhi_pkg" "$dhi_total" "$dhi_c" "$dhi_h" "$dhi_m" "$dhi_l" "$dhi_u"
	print_sep
}

APP_REPORT="$TMP_DIR/sample-mcp.txt"
DHI_REPORT="$TMP_DIR/sample-mcp-dhi.txt"

# Scan both launched images using host Docker Scout auth context (Docker Desktop login).
scan_image "sample-mcp:latest" "$APP_REPORT"
scan_image "sample-mcp-dhi:latest" "$DHI_REPORT"

print_table "$APP_REPORT" "$DHI_REPORT"
