#!/bin/bash

# This script downloads domain lists from various sources, processes them
# based on file type (YAML, list/conf, plain text, base64 encoded text),
# extracts domain names, and saves them into categorized, sorted, and unique .tmp files.


function GetData() {
    cnacc_domain=(
            "https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/apple-cn.txt"
            "https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/direct-list.txt"
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
        rm -rf ./gfwlist2* ./Temp && mkdir ./Temp && cd ./Temp



        # Helper function to download and process URLs based on their file extension
        process_url() {
            local url="$1"
            local output_file="$2"
            local is_base64_encoded="${3:-false}" # Default to false if not provided
            local content

            echo "Downloading: $url"
            content=$(curl -s "$url")

            if [ -z "$content" ]; then
                echo "Warning: Failed to download content from $url"
                return 1
            fi

            if [ "$is_base64_encoded" = "true" ]; then
                echo "Decoding base64 for: $url"
                # Attempt to decode; suppress errors and check exit status
                content=$(echo "$content" | base64 --decode 2>/dev/null)
                if [ $? -ne 0 ]; then
                    echo "Warning: Failed to base64 decode content from $url. Skipping this URL."
                    return 1
                fi
            fi

            local filename=$(basename "$url")
            local extension="${filename##*.}"

            # Remove query parameters from extension for better matching, e.g., 'file.txt?param=value'
            extension=$(echo "$extension" | cut -d'?' -f1)

            case "$extension" in
                yaml)
                    # Extract domains from YAML files
                    echo "$content" \
                        | grep -Ei '^\s*-\s*(domain|domain-suffix|domain-keyword|domain-regex)' \
                        | grep -Eo '[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' \
                        >> "$output_file"
                    ;;
                list|conf)
                    # Extract domains from .list or .conf files
                    echo "$content" \
                        | grep -Eo '[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' \
                        >> "$output_file"
                    ;;
                txt)
                    # Extract domains from plain .txt files (not base64 encoded, which are handled by is_base64_encoded param)
                    echo "$content" \
                        | grep -Eo '([a-zA-Z0-9.-]+\.[a-zA-Z]{2,})' \
                        >> "$output_file"
                    ;;
                *)
                    echo "Warning: Unknown file type for processing: $url (extension: $extension). Attempting generic text processing."
                    # Default to generic domain extraction if extension is unknown
                    echo "$content" \
                        | grep -Eo '([a-zA-Z0-9.-]+\.[a-zA-Z]{2,})' \
                        >> "$output_file"
                    ;;
            esac
        }

        echo "--- Starting data collection ---"

        # Process cnacc_domain URLs
        local CNACC_DOMAIN_OUTPUT="./cnacc_domain.tmp"
        > "$CNACC_DOMAIN_OUTPUT" # Clear the file before appending
        echo "Processing cnacc_domain sources..."
        for url in "${cnacc_domain[@]}"; do
            process_url "$url" "$CNACC_DOMAIN_OUTPUT"
        done
        sort -u "$CNACC_DOMAIN_OUTPUT" -o "$CNACC_DOMAIN_OUTPUT" # Sort and get unique entries
        echo "Generated: $CNACC_DOMAIN_OUTPUT with $(wc -l < "$CNACC_DOMAIN_OUTPUT") entries."

        # Process cnacc_trusted URLs
        local CNACC_TRUSTED_OUTPUT="./cnacc_trusted.tmp"
        > "$CNACC_TRUSTED_OUTPUT" # Clear the file before appending
        echo "Processing cnacc_trusted sources..."
        for url in "${cnacc_trusted[@]}"; do
            process_url "$url" "$CNACC_TRUSTED_OUTPUT"
        done
        sort -u "$CNACC_TRUSTED_OUTPUT" -o "$CNACC_TRUSTED_OUTPUT"
        echo "Generated: $CNACC_TRUSTED_OUTPUT with $(wc -l < "$CNACC_TRUSTED_OUTPUT") entries."

        # Process gfwlist_base64 URLs (requires base64 decoding)
        local GFWLIST_BASE64_OUTPUT="./gfwlist_base64.tmp"
        > "$GFWLIST_BASE64_OUTPUT" # Clear the file before appending
        echo "Processing gfwlist_base64 sources (with base64 decoding)..."
        for url in "${gfwlist_base64[@]}"; do
            process_url "$url" "$GFWLIST_BASE64_OUTPUT" "true" # Pass "true" to enable base64 decoding
        done
        sort -u "$GFWLIST_BASE64_OUTPUT" -o "$GFWLIST_BASE64_OUTPUT"
        echo "Generated: $GFWLIST_BASE64_OUTPUT with $(wc -l < "$GFWLIST_BASE64_OUTPUT") entries."

        # Process gfwlist_domain URLs
        local GFWLIST_DOMAIN_OUTPUT="./gfwlist_domain.tmp"
        > "$GFWLIST_DOMAIN_OUTPUT" # Clear the file before appending
        echo "Processing gfwlist_domain sources..."
        for url in "${gfwlist_domain[@]}"; do
            process_url "$url" "$GFWLIST_DOMAIN_OUTPUT"
        done
        sort -u "$GFWLIST_DOMAIN_OUTPUT" -o "$GFWLIST_DOMAIN_OUTPUT"
        echo "Generated: $GFWLIST_DOMAIN_OUTPUT with $(wc -l < "$GFWLIST_DOMAIN_OUTPUT") entries."

        # Process gfwlist2agh_modify URLs
        local GFWLIST2AGH_MODIFY_OUTPUT="./gfwlist2agh_modify.tmp"
        > "$GFWLIST2AGH_MODIFY_OUTPUT" # Clear the file before appending
        echo "Processing gfwlist2agh_modify sources..."
        for url in "${gfwlist2agh_modify[@]}"; do
            process_url "$url" "$GFWLIST2AGH_MODIFY_OUTPUT"
        done
        sort -u "$GFWLIST2AGH_MODIFY_OUTPUT" -o "$GFWLIST2AGH_MODIFY_OUTPUT"
        echo "Generated: $GFWLIST2AGH_MODIFY_OUTPUT with $(wc -l < "$GFWLIST2AGH_MODIFY_OUTPUT") entries."

        # Return to the original directory
        cd ..
        echo "--- Data collection complete. Processed files are in ./Temp/ ---"
}

# Analyse Data
function AnalyseData() {
    cnacc_data=($(cat "./cnacc_data.tmp" "./lite_cnacc_data.tmp" | sort -u))
    gfwlist_data=($(cat "./gfwlist_data.tmp" "./lite_gfwlist_data.tmp" | sort -u))
    lite_cnacc_data=($(cat "./lite_cnacc_data.tmp" | sort -u))
    lite_gfwlist_data=($(cat "./lite_gfwlist_data.tmp" | sort -u))

}
# Generate Rules
function GenerateRules() {
    function FileName() {
        if [ "${generate_file}" == "black" ] || [ "${generate_file}" == "whiteblack" ]; then
            generate_temp="black"
        elif [ "${generate_file}" == "white" ] || [ "${generate_file}" == "blackwhite" ]; then
            generate_temp="white"
        else
            generate_temp="debug"
        fi
        if [ "${software_name}" == "adguardhome" ] || [ "${software_name}" == "adguardhome_new" ] || [ "${software_name}" == "domain" ]; then
            file_extension="txt"
        elif [ "${software_name}" == "bind9" ] || [ "${software_name}" == "dnsmasq" ] || [ "${software_name}" == "smartdns" ] || [ "${software_name}" == "unbound" ]; then
            file_extension="conf"
        else
            file_extension="dev"
        fi
        if [ ! -d "../gfwlist2${software_name}" ]; then
            mkdir "../gfwlist2${software_name}"
        fi
        file_name="${generate_temp}list_${generate_mode}.${file_extension}"
        file_path="../gfwlist2${software_name}/${file_name}"
    }
    function GenerateDefaultUpstream() {
        case ${software_name} in
            adguardhome)
                if [ "${generate_mode}" == "full" ] || [ "${generate_mode}" == "lite" ]; then
                    if [ "${generate_file}" == "blackwhite" ]; then
                        for foreign_dns_task in "${!foreign_dns[@]}"; do
                            echo "${foreign_dns[$foreign_dns_task]}" >> "${file_path}"
                        done
                    elif [ "${generate_file}" == "whiteblack" ]; then
                        for domestic_dns_task in "${!domestic_dns[@]}"; do
                            echo "${domestic_dns[$domestic_dns_task]}" >> "${file_path}"
                        done
                    fi
                else
                    if [ "${generate_file}" == "black" ]; then
                        for domestic_dns_task in "${!domestic_dns[@]}"; do
                            echo "${domestic_dns[$domestic_dns_task]}" >> "${file_path}"
                        done
                    elif [ "${generate_file}" == "white" ]; then
                        for foreign_dns_task in "${!foreign_dns[@]}"; do
                            echo "${foreign_dns[$foreign_dns_task]}" >> "${file_path}"
                        done
                    fi
                fi
            ;;
            adguardhome_new)
                if [ "${generate_mode}" == "full" ] || [ "${generate_mode}" == "lite" ]; then
                    if [ "${generate_file}" == "blackwhite" ]; then
                        for foreign_dns_task in "${!foreign_dns[@]}"; do
                            echo "${foreign_dns[$foreign_dns_task]}" >> "${file_path}"
                        done
                    elif [ "${generate_file}" == "whiteblack" ]; then
                        for domestic_dns_task in "${!domestic_dns[@]}"; do
                            echo "${domestic_dns[$domestic_dns_task]}" >> "${file_path}"
                        done
                    fi
                else
                    if [ "${generate_file}" == "black" ]; then
                        for domestic_dns_task in "${!domestic_dns[@]}"; do
                            echo "${domestic_dns[$domestic_dns_task]}" >> "${file_path}"
                        done
                    elif [ "${generate_file}" == "white" ]; then
                        for foreign_dns_task in "${!foreign_dns[@]}"; do
                            echo "${foreign_dns[$foreign_dns_task]}" >> "${file_path}"
                        done
                    fi
                fi
            ;;
            *)
                exit 1
            ;;
        esac
    }
    case ${software_name} in
        adguardhome)
            domestic_dns=(
                # "https://dns.alidns.com:443/dns-query"
                # "https://dns.ipv6dns.com:443/dns-query"
                # "https://doh.360.cn:443/dns-query"
                "https://doh.pub:443/dns-query"
                # "tls://dns.alidns.com:853"
                # "tls://dns.ipv6dns.com:853"
                # "tls://dot.360.cn:853"
                # "tls://dot.pub:853"
            )
            foreign_dns=(
                # "https://dns.google:443/dns-query"
                "https://dns.opendns.com:443/dns-query"
                # "https://dns11.quad9.net:443/dns-query"
                # "https://dns64.dns.google:443/dns-query"
                # "tls://dns.google:853"
                # "tls://dns.opendns.com:853"
                # "tls://dns11.quad9.net:853"
                # "tls://dns64.dns.google:853"
            )
            function GenerateRulesHeader() {
                echo -n "[/" >> "${file_path}"
            }
            function GenerateRulesBody() {
                if [ "${generate_mode}" == "full" ] || [ "${generate_mode}" == "full_combine" ]; then
                    if [ "${generate_file}" == "black" ] || [ "${generate_file}" == "blackwhite" ]; then
                        for cnacc_data_task in "${!cnacc_data[@]}"; do
                            echo -n "${cnacc_data[$cnacc_data_task]}/" >> "${file_path}"
                        done
                    elif [ "${generate_file}" == "white" ] || [ "${generate_file}" == "whiteblack" ]; then
                        for gfwlist_data_task in "${!gfwlist_data[@]}"; do
                            echo -n "${gfwlist_data[$gfwlist_data_task]}/" >> "${file_path}"
                        done
                    fi
                elif [ "${generate_mode}" == "lite" ] || [ "${generate_mode}" == "lite_combine" ]; then
                    if [ "${generate_file}" == "black" ] || [ "${generate_file}" == "blackwhite" ]; then
                        for lite_cnacc_data_task in "${!lite_cnacc_data[@]}"; do
                            echo -n "${lite_cnacc_data[$lite_cnacc_data_task]}/" >> "${file_path}"
                        done
                    elif [ "${generate_file}" == "white" ] || [ "${generate_file}" == "whiteblack" ]; then
                        for lite_gfwlist_data_task in "${!lite_gfwlist_data[@]}"; do
                            echo -n "${lite_gfwlist_data[$lite_gfwlist_data_task]}/" >> "${file_path}"
                        done
                    fi
                fi
            }
            function GenerateRulesFooter() {
                if [ "${dns_mode}" == "default" ]; then
                    echo -e "]#" >> "${file_path}"
                elif [ "${dns_mode}" == "domestic" ]; then
                    echo -e "]${domestic_dns[domestic_dns_task]}" >> "${file_path}"
                elif [ "${dns_mode}" == "foreign" ]; then
                    echo -e "]${foreign_dns[foreign_dns_task]}" >> "${file_path}"
                fi
            }
            function GenerateRulesProcess() {
                GenerateRulesHeader
                GenerateRulesBody
                GenerateRulesFooter
            }
            if [ "${dns_mode}" == "default" ]; then
                FileName && GenerateDefaultUpstream && GenerateRulesProcess
            elif [ "${dns_mode}" == "domestic" ]; then
                FileName && GenerateDefaultUpstream && for domestic_dns_task in "${!domestic_dns[@]}"; do
                    GenerateRulesProcess
                done
            elif [ "${dns_mode}" == "foreign" ]; then
                FileName && GenerateDefaultUpstream && for foreign_dns_task in "${!foreign_dns[@]}"; do
                   GenerateRulesProcess
                done
            fi
        ;;
        adguardhome_new)
            domestic_dns=(
                # "https://dns.alidns.com:443/dns-query"
                # "https://dns.ipv6dns.com:443/dns-query"
                # "https://doh.360.cn:443/dns-query"
                "https://doh.pub:443/dns-query"
                "tls://dns.alidns.com:853"
                # "tls://dns.ipv6dns.com:853"
                # "tls://dot.360.cn:853"
                # "tls://dot.pub:853"
            )
            foreign_dns=(
                # "https://dns.google:443/dns-query"
                "https://dns.opendns.com:443/dns-query"
                # "https://dns11.quad9.net:443/dns-query"
                # "https://dns64.dns.google:443/dns-query"
                "tls://dns.google:853"
                # "tls://dns.opendns.com:853"
                # "tls://dns11.quad9.net:853"
                # "tls://dns64.dns.google:853"
            )
            function GenerateRulesHeader() {
                echo -n "[/" >> "${file_path}"
            }
            function GenerateRulesBody() {
                if [ "${generate_mode}" == "full" ] || [ "${generate_mode}" == "full_combine" ]; then
                    if [ "${generate_file}" == "black" ] || [ "${generate_file}" == "blackwhite" ]; then
                        for cnacc_data_task in "${!cnacc_data[@]}"; do
                            echo -n "${cnacc_data[$cnacc_data_task]}/" >> "${file_path}"
                        done
                    elif [ "${generate_file}" == "white" ] || [ "${generate_file}" == "whiteblack" ]; then
                        for gfwlist_data_task in "${!gfwlist_data[@]}"; do
                            echo -n "${gfwlist_data[$gfwlist_data_task]}/" >> "${file_path}"
                        done
                    fi
                elif [ "${generate_mode}" == "lite" ] || [ "${generate_mode}" == "lite_combine" ]; then
                    if [ "${generate_file}" == "black" ] || [ "${generate_file}" == "blackwhite" ]; then
                        for lite_cnacc_data_task in "${!lite_cnacc_data[@]}"; do
                            echo -n "${lite_cnacc_data[$lite_cnacc_data_task]}/" >> "${file_path}"
                        done
                    elif [ "${generate_file}" == "white" ] || [ "${generate_file}" == "whiteblack" ]; then
                        for lite_gfwlist_data_task in "${!lite_gfwlist_data[@]}"; do
                            echo -n "${lite_gfwlist_data[$lite_gfwlist_data_task]}/" >> "${file_path}"
                        done
                    fi
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
            function GenerateRulesProcess() {
                GenerateRulesHeader
                GenerateRulesBody
                GenerateRulesFooter
            }
            if [ "${dns_mode}" == "default" ]; then
                FileName && GenerateDefaultUpstream && GenerateRulesProcess
            elif [ "${dns_mode}" == "domestic" ]; then
                FileName && GenerateDefaultUpstream && GenerateRulesProcess
            elif [ "${dns_mode}" == "foreign" ]; then
                FileName && GenerateDefaultUpstream && GenerateRulesProcess
            fi
        ;;
        bind9)
            domestic_dns=(
                "223.5.5.5 port 53"
            )
            foreign_dns=(
                "8.8.8.8 port 53"
            )
            if [ "${generate_mode}" == "full" ]; then
                if [ "${generate_file}" == "black" ]; then
                    FileName && for gfwlist_data_task in "${!gfwlist_data[@]}"; do
                        echo -n "zone \"${gfwlist_data[$gfwlist_data_task]}.\" {type forward; forwarders { " >> "${file_path}"
                        for foreign_dns_task in "${!foreign_dns[@]}"; do
                            echo -n "${foreign_dns[$foreign_dns_task]}; " >> "${file_path}"
                        done
                        echo "}; };" >> "${file_path}"
                    done
                elif [ "${generate_file}" == "white" ]; then
                    FileName && for cnacc_data_task in "${!cnacc_data[@]}"; do
                        echo -n "zone \"${cnacc_data[$cnacc_data_task]}.\" {type forward; forwarders { " >> "${file_path}"
                        for domestic_dns_task in "${!domestic_dns[@]}"; do
                            echo -n "${domestic_dns[$domestic_dns_task]}; " >> "${file_path}"
                        done
                        echo "}; };" >> "${file_path}"
                    done
                fi
            elif [ "${generate_mode}" == "lite" ]; then
                if [ "${generate_file}" == "black" ]; then
                    FileName && for lite_gfwlist_data_task in "${!lite_gfwlist_data[@]}"; do
                        echo -n "zone \"${lite_gfwlist_data[$lite_gfwlist_data_task]}.\" {type forward; forwarders { " >> "${file_path}"
                        for foreign_dns_task in "${!foreign_dns[@]}"; do
                            echo -n "${foreign_dns[$foreign_dns_task]}; " >> "${file_path}"
                        done
                        echo "}; };" >> "${file_path}"
                    done
                elif [ "${generate_file}" == "white" ]; then
                    FileName && for lite_cnacc_data_task in "${!lite_cnacc_data[@]}"; do
                        echo -n "zone \"${lite_cnacc_data[$lite_cnacc_data_task]}.\" {type forward; forwarders { " >> "${file_path}"
                        for domestic_dns_task in "${!domestic_dns[@]}"; do
                            echo -n "${domestic_dns[$domestic_dns_task]}; " >> "${file_path}"
                        done
                        echo "}; };" >> "${file_path}"
                    done
                fi
            fi
        ;;
        dnsmasq)
            domestic_dns=(
                "223.5.5.5#53"
            )
            foreign_dns=(
                "8.8.8.8#53"
            )
            if [ "${generate_mode}" == "full" ]; then
                if [ "${generate_file}" == "black" ]; then
                    FileName && for gfwlist_data_task in "${!gfwlist_data[@]}"; do
                        for foreign_dns_task in "${!foreign_dns[@]}"; do
                            echo "server=/${gfwlist_data[$gfwlist_data_task]}/${foreign_dns[$foreign_dns_task]}" >> "${file_path}"
                        done
                    done
                elif [ "${generate_file}" == "white" ]; then
                    FileName && for cnacc_data_task in "${!cnacc_data[@]}"; do
                        for domestic_dns_task in "${!domestic_dns[@]}"; do
                            echo "server=/${cnacc_data[$cnacc_data_task]}/${domestic_dns[$domestic_dns_task]}" >> "${file_path}"
                        done
                    done
                fi
            elif [ "${generate_mode}" == "lite" ]; then
                if [ "${generate_file}" == "black" ]; then
                    FileName && for lite_gfwlist_data_task in "${!lite_gfwlist_data[@]}"; do
                        for foreign_dns_task in "${!foreign_dns[@]}"; do
                            echo "server=/${lite_gfwlist_data[$lite_gfwlist_data_task]}/${foreign_dns[$foreign_dns_task]}" >> "${file_path}"
                        done
                    done
                elif [ "${generate_file}" == "white" ]; then
                    FileName && for lite_cnacc_data_task in "${!lite_cnacc_data[@]}"; do
                        for domestic_dns_task in "${!domestic_dns[@]}"; do
                            echo "server=/${lite_cnacc_data[$lite_cnacc_data_task]}/${domestic_dns[$domestic_dns_task]}" >> "${file_path}"
                        done
                    done
                fi
            fi
        ;;
        domain)
            if [ "${generate_mode}" == "full" ]; then
                if [ "${generate_file}" == "black" ]; then
                    FileName && for gfwlist_data_task in "${!gfwlist_data[@]}"; do
                        echo "${gfwlist_data[$gfwlist_data_task]}" >> "${file_path}"
                    done
                elif [ "${generate_file}" == "white" ]; then
                    FileName && for cnacc_data_task in "${!cnacc_data[@]}"; do
                        echo "${cnacc_data[$cnacc_data_task]}" >> "${file_path}"
                    done
                fi
            elif [ "${generate_mode}" == "lite" ]; then
                if [ "${generate_file}" == "black" ]; then
                    FileName && for lite_gfwlist_data_task in "${!lite_gfwlist_data[@]}"; do
                        echo "${lite_gfwlist_data[$lite_gfwlist_data_task]}" >> "${file_path}"
                    done
                elif [ "${generate_file}" == "white" ]; then
                    FileName && for lite_cnacc_data_task in "${!lite_cnacc_data[@]}"; do
                        echo "${lite_cnacc_data[$lite_cnacc_data_task]}" >> "${file_path}"
                    done
                fi
            fi
        ;;
        smartdns)
            if [ "${generate_mode}" == "full" ]; then
                if [ "${generate_file}" == "black" ]; then
                    FileName && for gfwlist_data_task in "${!gfwlist_data[@]}"; do
                        echo "${gfwlist_data[$gfwlist_data_task]}" >> "${file_path}"
                    done
                elif [ "${generate_file}" == "white" ]; then
                    FileName && for cnacc_data_task in "${!cnacc_data[@]}"; do
                        echo "${cnacc_data[$cnacc_data_task]}" >> "${file_path}"
                    done
                fi
            elif [ "${generate_mode}" == "lite" ]; then
                if [ "${generate_file}" == "black" ]; then
                    FileName && for lite_gfwlist_data_task in "${!lite_gfwlist_data[@]}"; do
                        echo "${lite_gfwlist_data[$lite_gfwlist_data_task]}" >> "${file_path}"
                    done
                elif [ "${generate_file}" == "white" ]; then
                    FileName && for lite_cnacc_data_task in "${!lite_cnacc_data[@]}"; do
                        echo "${lite_cnacc_data[$lite_cnacc_data_task]}" >> "${file_path}"
                    done
                fi
            fi
        ;;
        unbound)
            domestic_dns=(
                "223.5.5.5@853#dns.alidns.com"
            )
            foreign_dns=(
                "8.8.8.8@853#dns.google"
            )
            forward_ssl_tls_upstream="yes"
            function GenerateRulesHeader() {
                echo "forward-zone:" >> "${file_path}"
            }
            function GenerateRulesFooter() {
                if [ "${dns_mode}" == "domestic" ]; then
                    for domestic_dns_task in "${!domestic_dns[@]}"; do
                        echo "    forward-addr: \"${domestic_dns[$domestic_dns_task]}\"" >> "${file_path}"
                    done
                elif [ "${dns_mode}" == "foreign" ]; then
                    for foreign_dns_task in "${!foreign_dns[@]}"; do
                        echo "    forward-addr: \"${foreign_dns[$foreign_dns_task]}\"" >> "${file_path}"
                    done
                fi
                echo "    forward-first: \"yes\"" >> "${file_path}"
                echo "    forward-no-cache: \"yes\"" >> "${file_path}"
                echo "    forward-ssl-upstream: \"${forward_ssl_tls_upstream}\"" >> "${file_path}"
                echo "    forward-tls-upstream: \"${forward_ssl_tls_upstream}\"" >> "${file_path}"
            }
            if [ "${generate_mode}" == "full" ]; then
                if [ "${generate_file}" == "black" ]; then
                    FileName && for gfwlist_data_task in "${!gfwlist_data[@]}"; do
                        GenerateRulesHeader && echo "    name: \"${gfwlist_data[$gfwlist_data_task]}.\"" >> "${file_path}" && GenerateRulesFooter
                    done
                elif [ "${generate_file}" == "white" ]; then
                    FileName && for cnacc_data_task in "${!cnacc_data[@]}"; do
                        GenerateRulesHeader && echo "    name: \"${cnacc_data[$cnacc_data_task]}.\"" >> "${file_path}" && GenerateRulesFooter
                    done
                fi
            elif [ "${generate_mode}" == "lite" ]; then
                if [ "${generate_file}" == "black" ]; then
                    FileName && for lite_gfwlist_data_task in "${!lite_gfwlist_data[@]}"; do
                        GenerateRulesHeader && echo "    name: \"${lite_gfwlist_data[$lite_gfwlist_data_task]}.\"" >> "${file_path}" && GenerateRulesFooter
                    done
                elif [ "${generate_file}" == "white" ]; then
                    FileName && for lite_cnacc_data_task in "${!lite_cnacc_data[@]}"; do
                        GenerateRulesHeader && echo "    name: \"${lite_cnacc_data[$lite_cnacc_data_task]}.\"" >> "${file_path}" && GenerateRulesFooter
                    done
                fi
            fi
        ;;
        *)
            exit 1
    esac
}
# Output Data
function OutputData() {
    ## AdGuard Home (New)
    software_name="adguardhome_new" && generate_file="black" && generate_mode="full_combine" && dns_mode="default" && GenerateRules
    software_name="adguardhome_new" && generate_file="black" && generate_mode="lite_combine" && dns_mode="default" && GenerateRules
    software_name="adguardhome_new" && generate_file="white" && generate_mode="full_combine" && dns_mode="default" && GenerateRules
    software_name="adguardhome_new" && generate_file="white" && generate_mode="lite_combine" && dns_mode="default" && GenerateRules
    software_name="adguardhome_new" && generate_file="blackwhite" && generate_mode="full_combine" && dns_mode="domestic" && GenerateRules
    software_name="adguardhome_new" && generate_file="blackwhite" && generate_mode="lite_combine" && dns_mode="domestic" && GenerateRules
    software_name="adguardhome_new" && generate_file="whiteblack" && generate_mode="full_combine" && dns_mode="foreign" && GenerateRules
    software_name="adguardhome_new" && generate_file="whiteblack" && generate_mode="lite_combine" && dns_mode="foreign" && GenerateRules
    software_name="adguardhome_new" && generate_file="blackwhite" && generate_mode="full" && dns_mode="domestic" && GenerateRules
    software_name="adguardhome_new" && generate_file="blackwhite" && generate_mode="lite" && dns_mode="domestic" && GenerateRules
    software_name="adguardhome_new" && generate_file="whiteblack" && generate_mode="full" && dns_mode="foreign" && GenerateRules
    software_name="adguardhome_new" && generate_file="whiteblack" && generate_mode="lite" && dns_mode="foreign" && GenerateRules
    ## SmartDNS
    software_name="smartdns" && generate_file="black" && generate_mode="full" && foreign_group="foreign" && GenerateRules
    software_name="smartdns" && generate_file="black" && generate_mode="lite" && foreign_group="foreign" && GenerateRules
    software_name="smartdns" && generate_file="white" && generate_mode="full" && domestic_group="domestic" && GenerateRules
    software_name="smartdns" && generate_file="white" && generate_mode="lite" && domestic_group="domestic" && GenerateRules


    cd .. && rm -rf ./Temp
    exit 0
}

## Process
# Call GetData
GetData
# Call AnalyseData
AnalyseData
# Call OutputData
OutputData
