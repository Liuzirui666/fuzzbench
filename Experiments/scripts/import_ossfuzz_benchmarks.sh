#!/usr/bin/env bash
set -euo pipefail

# Run this script from fuzzbench/Experiments.
if [ ! -d "benchmarks" ]; then
  echo "Error: benchmarks/ directory not found. Run this from fuzzbench/Experiments." >&2
  exit 1
fi

if [ ! -d "third_party/oss-fuzz/projects" ]; then
  echo "Error: third_party/oss-fuzz/projects not found." >&2
  echo "Make sure you cloned OSS-Fuzz into third_party/oss-fuzz." >&2
  exit 1
fi

OSS_FUZZ_ROOT="third_party/oss-fuzz/projects"

# Each entry:  BENCH_NAME  PROJECT  FUZZ_TARGET
benchmarks=(
  "arrow_parquet-arrow-fuzz                arrow      parquet-arrow-fuzz"
  "aspell_aspell_fuzzer                    aspell     aspell_fuzzer"
  "ffmpeg_ffmpeg_demuxer_fuzzer            ffmpeg     ffmpeg_demuxer_fuzzer"
  "grok_grk_decompress_fuzzer              grok       grk_decompress_fuzzer"
  "harfbuzz_hb-subset-fuzzer               harfbuzz   hb-subset-fuzzer"
  "libhevc_hevc_dec_fuzzer                 libhevc    hevc_dec_fuzzer"
  "libgit2_objects_fuzzer                  libgit2    objects_fuzzer"
  "libhtp_fuzz_htp                         libhtp     fuzz_htp"
  "libxml2_libxml2_xml_reader_for_file_fuzzer libxml2 libxml2_xml_reader_for_file_fuzzer"
  "matio_matio_fuzzer                      matio      matio_fuzzer"
  "njs_njs_process_script_fuzzer           njs        njs_process_script_fuzzer"
  "openh264_decoder_fuzzer                 openh264   decoder_fuzzer"
  "php_php-fuzz-parser-2020-07-25          php        php-fuzz-parser"
  "poppler_pdf_fuzzer                      poppler    pdf_fuzzer"
  "quickjs_eval-2020-01-05                 quickjs    eval"
  "stb_stbi_read_fuzzer                    stb        stbi_read_fuzzer"
  "systemd_fuzz-varlink                    systemd    fuzz-varlink"
  "wireshark_fuzzshark_ip                  wireshark  fuzzshark_ip"
)

for entry in "${benchmarks[@]}"; do
  # shellcheck disable=SC2086
  set -- $entry
  BENCH_NAME="$1"
  PROJECT="$2"
  FUZZ_TARGET="$3"

  SRC_DIR="${OSS_FUZZ_ROOT}/${PROJECT}"
  DEST_DIR="benchmarks/${BENCH_NAME}"

  echo "=== Importing ${BENCH_NAME} from OSS-Fuzz project ${PROJECT} (target ${FUZZ_TARGET}) ==="

  if [ ! -d "${SRC_DIR}" ]; then
    echo "  ERROR: ${SRC_DIR} does not exist. Skipping this benchmark." >&2
    continue
  fi

  mkdir -p "${DEST_DIR}"

  # Copy core integration files from OSS-Fuzz.
  if [ -f "${SRC_DIR}/Dockerfile" ]; then
    cp "${SRC_DIR}/Dockerfile" "${DEST_DIR}/"
  else
    echo "  WARNING: No Dockerfile in ${SRC_DIR}" >&2
  fi

  if [ -f "${SRC_DIR}/build.sh" ]; then
    cp "${SRC_DIR}/build.sh" "${DEST_DIR}/"
  else
    echo "  WARNING: No build.sh in ${SRC_DIR}" >&2
  fi

  # Optional: copy any *.options files (may not be needed, but cheap to keep).
  if ls "${SRC_DIR}"/*.options >/dev/null 2>&1; then
    cp "${SRC_DIR}"/*.options "${DEST_DIR}/" || true
  fi

  # Optional: copy seeds if project keeps them under projects/<project>/seeds
  if [ -d "${SRC_DIR}/seeds" ]; then
    cp -r "${SRC_DIR}/seeds" "${DEST_DIR}/"
  fi

  # Minimal benchmark.yaml as per FuzzBench docs.
  cat > "${DEST_DIR}/benchmark.yaml" << EOFYAML
fuzz_target: ${FUZZ_TARGET}
project: ${PROJECT}
EOFYAML

done

echo "=== Done. New benchmarks should now be under benchmarks/."
