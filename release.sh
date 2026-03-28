#!/bin/bash
set -euo pipefail

function Cleanup() {
    rm -rf ./Temp
}
trap Cleanup EXIT

function GetData() {
    cnacc_domain=(
        "https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/apple-cn.txt"
        "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/refs/heads/master/rule/Clash/Apple/Apple_Classical_No_Resolve.yaml"
        "https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/direct-list.txt"
        "https://raw.githubusercontent.com/madswaord/surgejourney/refs/heads/main/Clash/Ruleset/Binance.txt"
        "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/refs/heads/master/rule/Clash/GoogleFCM/GoogleFCM.yaml"
        "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/refs/heads/master/rule/Clash/GovCN/GovCN.yaml"
        "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/refs/heads/master/rule/Clash/China/China_Domain.txt"
        "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/refs/heads/master/rule/Clash/ChinaMaxNoIP/ChinaMaxNoIP_Domain.txt"
        "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/refs/heads/master/rule/Clash/DouYin/DouYin.yaml"
        "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/refs/heads/master/rule/Clash/Tencent/Tencent.yaml"
        "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/refs/heads/master/rule/Clash/UnionPay/UnionPay.yaml"
        "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/refs/heads/master/rule/Clash/OPPO/OPPO.yaml"
        "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/refs/heads/master/rule/Clash/Vivo/Vivo.yaml"
        "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/refs/heads/master/rule/Clash/XiaoMi/XiaoMi.yaml"
        "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/refs/heads/master/rule/Clash/XiaoHongShu/XiaoHongShu.yaml"
        "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/refs/heads/master/rule/Clash/ChinaUnicom/ChinaUnicom.yaml"
        "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/refs/heads/master/rule/Clash/ChinaTelecom/ChinaTelecom.yaml"
        "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/refs/heads/master/rule/Clash/ChinaMobile/ChinaMobile.yaml"
        "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/refs/heads/master/rule/Clash/ChinaNoMedia/ChinaNoMedia_Domain.txt"
        "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/refs/heads/master/rule/Clash/JingDong/JingDong.yaml"
        "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/refs/heads/master/rule/Clash/SteamCN/SteamCN.yaml"
        "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/refs/heads/master/rule/Clash/Binance/Binance_No_Resolve.yaml"
    )
    cnacc_trusted=(
        "https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/accelerated-domains.china.conf"
        "https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/apple.china.conf"
    )
    gfwlist_base64=(
        "https://raw.githubusercontent.com/Loukky/gfwlist-by-loukky/master/gfwlist.txt"
        "https://raw.githubusercontent.com/gfwlist/gfwlist/master/gfwlist.txt"
        "https://raw.githubusercontent.com/poctopus/gfwlist-plus/master/gfwlist-plus.txt"
    )
    gfwlist_domain=(
        "https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/gfw.txt"
        "https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/greatfire.txt"
        "https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/proxy-list.txt"
        "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/refs/heads/master/rule/Clash/Proxy/Proxy_Domain_For_Clash.txt"
        "https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/google-cn.txt"
        "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/refs/heads/master/rule/Clash/Crypto/Crypto.yaml"
        "https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Surge/Global/Global_Domain.list"
        "https://raw.githubusercontent.com/pexcn/gfwlist-extras/master/gfwlist-extras.txt"
    )
    gfwlist2agh_modify=(
        "https://raw.githubusercontent.com/madswaord/GFWList2AGH/refs/heads/source/data/data_modify.txt"
    )

    rm -rf ./gfwlist2* ./Temp
    mkdir -p ./Temp/raw
    cd ./Temp

    function DownloadToFile() {
        local url="$1"
        local output="$2"
        local attempt=1
        while [ ${attempt} -le 4 ]; do
            if curl -fsSL --connect-timeout 20 --max-time 180 -A "Mozilla/5.0" "${url}" -o "${output}"; then
                return 0
            fi
            attempt=$((attempt + 1))
            sleep $((attempt * 2))
        done
        echo "Download failed: ${url}" >&2
        return 1
    }

    function DownloadGroup() {
        local group="$1"
        shift
        local -a urls=("$@")
        local index=1
        local file
        for url in "${urls[@]}"; do
            printf -v file "./raw/%s_%02d.txt" "${group}" "${index}"
            DownloadToFile "${url}" "${file}"
            index=$((index + 1))
        done
    }

    DownloadGroup "cnacc_domain" "${cnacc_domain[@]}"
    DownloadGroup "cnacc_trusted" "${cnacc_trusted[@]}"
    DownloadGroup "gfwlist_base64" "${gfwlist_base64[@]}"
    DownloadGroup "gfwlist_domain" "${gfwlist_domain[@]}"
    DownloadGroup "gfwlist2agh_modify" "${gfwlist2agh_modify[@]}"
}

function AnalyseData() {
    python3 - <<'PY'
import base64
import pathlib
import re
import sys
from urllib.parse import urlparse

workdir = pathlib.Path('.')
rawdir = workdir / 'raw'

DOMAIN_RE = re.compile(r'^(?=.{1,253}$)(?!-)(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,63}$', re.I)


def read_text(path: pathlib.Path) -> str:
    data = path.read_bytes()
    try:
        return data.decode('utf-8')
    except UnicodeDecodeError:
        return data.decode('utf-8', 'replace')


def normalize_domain(value: str):
    value = value.strip().lower()
    value = value.lstrip('.')
    if value.startswith('+.'):
        value = value[2:]
    value = value.strip('.')
    if not value or len(value) > 253:
        return None
    if DOMAIN_RE.match(value):
        return value
    return None


def write_lines(path: pathlib.Path, values):
    path.write_text(''.join(f'{v}\n' for v in sorted(set(values))), encoding='utf-8')


def parse_plain_or_mixed(path: pathlib.Path):
    domains = set()
    for raw_line in read_text(path).splitlines():
        line = raw_line.strip()
        if not line or line.startswith('#'):
            continue
        if line.startswith('full:') or line.startswith('domain:'):
            value = line.split(':', 1)[1]
            domain = normalize_domain(value)
            if domain:
                domains.add(domain)
            continue
        domain = normalize_domain(line)
        if domain:
            domains.add(domain)
    return domains


def parse_loyalsoldier(path: pathlib.Path):
    domains = set()
    for raw_line in read_text(path).splitlines():
        line = raw_line.strip()
        if not line or line.startswith('#'):
            continue
        if not (line.startswith('full:') or line.startswith('domain:')):
            continue
        value = line.split(':', 1)[1]
        domain = normalize_domain(value)
        if domain:
            domains.add(domain)
    return domains


def parse_dnsmasq(path: pathlib.Path):
    domains = set()
    for raw_line in read_text(path).splitlines():
        line = raw_line.strip()
        if not line.startswith('server=/'):
            continue
        parts = line.split('/')
        if len(parts) < 3:
            continue
        domain = normalize_domain(parts[1])
        if domain:
            domains.add(domain)
    return domains


def parse_clash_yaml(path: pathlib.Path):
    domains = set()
    for raw_line in read_text(path).splitlines():
        line = raw_line.strip()
        if not line.startswith('- '):
            continue
        payload = line[2:]
        if payload.startswith('DOMAIN,'):
            value = payload.split(',', 1)[1]
            domain = normalize_domain(value)
            if domain:
                domains.add(domain)
        elif payload.startswith('DOMAIN-SUFFIX,'):
            value = payload.split(',', 1)[1]
            domain = normalize_domain(value)
            if domain:
                domains.add(domain)
    return domains


def parse_gfwlist(path: pathlib.Path):
    raw_text = read_text(path)
    compact = ''.join(line.strip() for line in raw_text.splitlines() if line.strip())
    decoded = raw_text
    try:
        decoded_candidate = base64.b64decode(compact, validate=False).decode('utf-8', 'replace')
        if '||' in decoded_candidate or '[AutoProxy' in decoded_candidate or '@@' in decoded_candidate:
            decoded = decoded_candidate
    except Exception:
        decoded = raw_text

    domains = set()
    for raw_line in decoded.splitlines():
        line = raw_line.strip()
        if not line or line.startswith('!') or line.startswith('['):
            continue
        if line.startswith('@@||') or line.startswith('||'):
            if line.startswith('@@||'):
                candidate = line[4:]
            else:
                candidate = line[2:]
            candidate = re.split(r'[\^/$*]', candidate, 1)[0]
            candidate = candidate.split(':', 1)[0]
            domain = normalize_domain(candidate)
            if domain:
                domains.add(domain)
            continue
        if line.startswith('@@|http://') or line.startswith('@@|https://') or line.startswith('|http://') or line.startswith('|https://'):
            if line.startswith('@@|'):
                url = line[3:]
            else:
                url = line[1:]
            try:
                host = urlparse(url).hostname
            except Exception:
                host = None
            domain = normalize_domain(host or '')
            if domain:
                domains.add(domain)
            continue
        domain = normalize_domain(line)
        if domain:
            domains.add(domain)
    return domains


def parse_modify(path: pathlib.Path):
    rules = {
        'cnacc_addition': set(),
        'cnacc_subtraction': set(),
        'cnacc_exclusion': set(),
        'cnacc_keyword': set(),
        'gfwlist_addition': set(),
        'gfwlist_subtraction': set(),
        'gfwlist_exclusion': set(),
        'gfwlist_keyword': set(),
    }
    addition_map = {
        '@%@': ('cnacc_addition',),
        '@%!': ('cnacc_addition', 'gfwlist_subtraction'),
        '!&@': ('cnacc_addition', 'gfwlist_subtraction'),
        '@@@': ('cnacc_addition', 'gfwlist_addition'),
        '@&@': ('gfwlist_addition',),
        '@&!': ('gfwlist_addition', 'cnacc_subtraction'),
        '!%@': ('gfwlist_addition', 'cnacc_subtraction'),
    }
    subtraction_map = {
        '!%!': ('cnacc_subtraction',),
        '@&!': ('cnacc_subtraction',),
        '!%@': ('cnacc_subtraction',),
        '!!!': ('cnacc_subtraction', 'gfwlist_subtraction'),
        '!&!': ('gfwlist_subtraction',),
        '@%!': ('gfwlist_subtraction',),
        '!&@': ('gfwlist_subtraction',),
    }
    exclusion_map = {
        '*%*': ('cnacc_exclusion',),
        '***': ('cnacc_exclusion', 'gfwlist_exclusion'),
        '*&*': ('gfwlist_exclusion',),
    }
    keyword_map = {
        '!%*': ('cnacc_keyword',),
        '!**': ('cnacc_keyword', 'gfwlist_keyword'),
        '!&*': ('gfwlist_keyword',),
    }
    prefixes = sorted(set(addition_map) | set(subtraction_map) | set(exclusion_map) | set(keyword_map), key=len, reverse=True)

    for raw_line in read_text(path).splitlines():
        line = raw_line.strip()
        if not line or line.startswith('#'):
            continue
        matched = False
        for prefix in prefixes:
            token = f'({prefix})'
            if not line.startswith(token):
                continue
            value = line[len(token):].strip().lower().lstrip('.').strip('.')
            matched = True
            if prefix in keyword_map:
                if value:
                    for key in keyword_map[prefix]:
                        rules[key].add(value)
            else:
                domain = normalize_domain(value)
                if domain:
                    if prefix in addition_map:
                        for key in addition_map[prefix]:
                            rules[key].add(domain)
                    if prefix in subtraction_map:
                        for key in subtraction_map[prefix]:
                            rules[key].add(domain)
                    if prefix in exclusion_map:
                        for key in exclusion_map[prefix]:
                            rules[key].add(domain)
            break
        if not matched:
            continue
    return rules


def apply_exclusion(domains, exclusion, keywords):
    results = set()
    for domain in domains:
        if domain in exclusion:
            continue
        if any(domain == ex or domain.endswith('.' + ex) for ex in exclusion):
            continue
        if any(keyword and keyword in domain for keyword in keywords):
            continue
        results.add(domain)
    return results


cnacc_domains = set()
for path in sorted(rawdir.glob('cnacc_domain_*.txt')):
    if path.name.endswith('.yaml.txt'):
        continue

for path in sorted(rawdir.glob('cnacc_domain_*')):
    if path.suffix == '.txt' and path.name in {'cnacc_domain_01_apple-cn.txt', 'cnacc_domain_03_direct-list.txt'}:
        cnacc_domains |= parse_plain_or_mixed(path)
    elif path.suffix == '.yaml':
        cnacc_domains |= parse_clash_yaml(path)
    else:
        cnacc_domains |= parse_plain_or_mixed(path)

cnacc_trust = set()
for path in sorted(rawdir.glob('cnacc_trusted_*')):
    cnacc_trust |= parse_dnsmasq(path)

# gfw domain sources
gfw_domains = set()
for path in sorted(rawdir.glob('gfwlist_domain_*')):
    if path.name in {'gfwlist_domain_05_google-cn.txt', 'gfwlist_domain_03_proxy-list.txt'}:
        gfw_domains |= parse_plain_or_mixed(path)
    elif path.suffix == '.yaml':
        gfw_domains |= parse_clash_yaml(path)
    else:
        gfw_domains |= parse_plain_or_mixed(path)

for path in sorted(rawdir.glob('gfwlist_base64_*')):
    gfw_domains |= parse_gfwlist(path)

modify_rules = parse_modify(next(rawdir.glob('gfwlist2agh_modify_*')))

cnacc_filtered = apply_exclusion(cnacc_domains, modify_rules['cnacc_exclusion'], modify_rules['cnacc_keyword'])
gfw_filtered = apply_exclusion(gfw_domains, modify_rules['gfwlist_exclusion'], modify_rules['gfwlist_keyword'])

cnacc_raw = cnacc_filtered - gfw_filtered
gfw_raw = gfw_filtered - cnacc_filtered

gfw_raw = gfw_raw - cnacc_trust

cnacc_added = cnacc_raw | cnacc_trust | modify_rules['cnacc_addition']
gfw_added = gfw_raw | modify_rules['gfwlist_addition']

cnacc_data = sorted(cnacc_added - modify_rules['cnacc_subtraction'])
gfwlist_data = sorted(gfw_added - modify_rules['gfwlist_subtraction'])

write_lines(workdir / 'cnacc_data.tmp', cnacc_data)
write_lines(workdir / 'gfwlist_data.tmp', gfwlist_data)
write_lines(workdir / 'cnacc_trust.tmp', cnacc_trust)
write_lines(workdir / 'cnacc_checklist.tmp', cnacc_domains)
write_lines(workdir / 'gfwlist_checklist.tmp', gfw_domains)
write_lines(workdir / 'cnacc_addition.tmp', modify_rules['cnacc_addition'])
write_lines(workdir / 'gfwlist_addition.tmp', modify_rules['gfwlist_addition'])
write_lines(workdir / 'cnacc_subtraction.tmp', modify_rules['cnacc_subtraction'])
write_lines(workdir / 'gfwlist_subtraction.tmp', modify_rules['gfwlist_subtraction'])
write_lines(workdir / 'cnacc_exclusion.tmp', modify_rules['cnacc_exclusion'])
write_lines(workdir / 'gfwlist_exclusion.tmp', modify_rules['gfwlist_exclusion'])
write_lines(workdir / 'cnacc_keyword.tmp', modify_rules['cnacc_keyword'])
write_lines(workdir / 'gfwlist_keyword.tmp', modify_rules['gfwlist_keyword'])
PY

    mapfile -t cnacc_data < ./cnacc_data.tmp
    mapfile -t gfwlist_data < ./gfwlist_data.tmp
}

function GenerateRules() {
    function FileName() {
        if [ "${generate_file}" == "black" ] || [ "${generate_file}" == "whiteblack" ]; then
            generate_temp="black"
        elif [ "${generate_file}" == "white" ] || [ "${generate_file}" == "blackwhite" ]; then
            generate_temp="white"
        else
            generate_temp="debug"
        fi
        if [ "${software_name}" == "adguardhome_new" ] || [ "${software_name}" == "domain" ]; then
            file_extension="txt"
        elif [ "${software_name}" == "smartdns" ]; then
            file_extension="conf"
        else
            file_extension="dev"
        fi
        if [ ! -d "../gfwlist2${software_name}" ]; then
            mkdir "../gfwlist2${software_name}"
        fi
        file_name="${generate_temp}list_${generate_mode}.${file_extension}"
        file_path="../gfwlist2${software_name}/${file_name}"
        : > "${file_path}"
    }

    case ${software_name} in
        adguardhome_new)
            FileName
            domestic_dns=(
                "https://doh.pub:443/dns-query"
                "tls://dns.alidns.com:853"
            )
            foreign_dns=(
                "https://dns.opendns.com:443/dns-query"
                "tls://dns.google:853"
            )
            function GenerateRulesHeader() {
                echo -n "[/" >> "${file_path}"
            }
            function GenerateRulesBody() {
                if [ "${generate_file}" == "black" ] || [ "${generate_file}" == "blackwhite" ]; then
                    for cnacc_data_task in "${!cnacc_data[@]}"; do
                        echo -n "${cnacc_data[$cnacc_data_task]}/" >> "${file_path}"
                    done
                elif [ "${generate_file}" == "white" ] || [ "${generate_file}" == "whiteblack" ]; then
                    for gfwlist_data_task in "${!gfwlist_data[@]}"; do
                        echo -n "${gfwlist_data[$gfwlist_data_task]}/" >> "${file_path}"
                    done
                fi
            }
            function GenerateRulesFooter() {
                if [ "${dns_mode}" == "default" ]; then
                    echo -e "]#" >> "${file_path}"
                elif [ "${dns_mode}" == "domestic" ]; then
                    echo -e "]${domestic_dns[*]}" >> "${file_path}"
                elif [ "${dns_mode}" == "foreign" ]; then
                    echo -e "]${foreign_dns[*]}" >> "${file_path}"
                fi
            }
            GenerateRulesHeader
            GenerateRulesBody
            GenerateRulesFooter
        ;;
        smartdns)
            FileName
            if [ "${generate_file}" == "black" ]; then
                for gfwlist_data_task in "${!gfwlist_data[@]}"; do
                    echo "${gfwlist_data[$gfwlist_data_task]}" >> "${file_path}"
                done
            elif [ "${generate_file}" == "white" ]; then
                for cnacc_data_task in "${!cnacc_data[@]}"; do
                    echo "${cnacc_data[$cnacc_data_task]}" >> "${file_path}"
                done
            fi
        ;;
        domain)
            FileName
            if [ "${generate_file}" == "black" ]; then
                for gfwlist_data_task in "${!gfwlist_data[@]}"; do
                    echo "${gfwlist_data[$gfwlist_data_task]}" >> "${file_path}"
                done
            elif [ "${generate_file}" == "white" ]; then
                for cnacc_data_task in "${!cnacc_data[@]}"; do
                    echo "${cnacc_data[$cnacc_data_task]}" >> "${file_path}"
                done
            fi
        ;;
        *)
            exit 1
        ;;
    esac
}

function OutputData() {
    software_name="adguardhome_new" && generate_file="black" && generate_mode="full_combine" && dns_mode="default" && GenerateRules
    software_name="adguardhome_new" && generate_file="white" && generate_mode="full_combine" && dns_mode="default" && GenerateRules
    software_name="adguardhome_new" && generate_file="blackwhite" && generate_mode="full_combine" && dns_mode="domestic" && GenerateRules
    software_name="adguardhome_new" && generate_file="whiteblack" && generate_mode="full_combine" && dns_mode="foreign" && GenerateRules
    software_name="adguardhome_new" && generate_file="blackwhite" && generate_mode="full" && dns_mode="domestic" && GenerateRules
    software_name="adguardhome_new" && generate_file="whiteblack" && generate_mode="full" && dns_mode="foreign" && GenerateRules

    software_name="smartdns" && generate_file="black" && generate_mode="full" && GenerateRules
    software_name="smartdns" && generate_file="white" && generate_mode="full" && GenerateRules

    software_name="domain" && generate_file="black" && generate_mode="full" && GenerateRules
    software_name="domain" && generate_file="white" && generate_mode="full" && GenerateRules
}

GetData
AnalyseData
OutputData
