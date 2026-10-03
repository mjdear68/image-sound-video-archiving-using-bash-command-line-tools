#!/bin/bash

# Global variables
regex_ext='.*\.(jpg|jpeg|flac)' # Cleaned up for posix-extended
std_ext='jpg' # Extension for img_rename

# Helper function: Validates if a directory exists
check_dir() {
	# Declare local variables
    local dir="$1"

    if [ -z "$dir" ] || [ ! -d "$dir" ]; then
        echo "Error: Input directory '${dir:-<unspecified>}' does not exist." >&2
        return 1
    fi
}

###########
# Image Functions
###########

img_rename() {
    # Safety Check: Ensure all arguments are provided
    if [ -z "$1" ] || [ -z "$2" ]|| [ -z "$3" ]; then
        echo "Usage: img_rename [input_dir] [output_dir] [extension]"
        echo "Example: img_rename ./input ./output jpg"
        return 1
    fi
    
	# Declare local variables
	local input=$1    # input directory
    local output=$2   # output directory
	local ext=$3	  # output file extension
	
	# Check if input directory exists
    check_dir "$input" || return 1
	
    # Proceed with function execution
    find "$input" -regextype posix-extended -type f -iregex "$regex_ext" | \
        exiftool -d "%Y%m%d_%H%M%S" \
		"-filename<$output/\${model;tr/ /_/;s/__+/_/g}-\${datetimeoriginal}%-c.$ext" \
             -r -o .  -@ -
}

img_group() {
    # Safety Check: Ensure all arguments are provided
    if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
        echo "Usage: img_group_mins [input_dir] [output_dir] [interval_in_minutes] "
        echo "Example: img_group_mins ./input ./output 30"
        return 1
    fi
	
	# Declare local variables
    local input=$1    # input directory
    local output=$2   # output directory
    local mins=$3     # minutes per interval
	
	# Check if input directory exists
    check_dir "$input" || return 1
	
	# Proceed with function execution
    find "$input" -regextype posix-extended -type f -iregex "$regex_ext" | \
    exiftool  '-Directory<$CreateDate/${CreateDate#;/(\d+):\d+$/;$_=sprintf("%02d",int($1/'"$mins"')*'"$mins"')}min' \
             -o . -d "$output/%Y-%m-%d_%H" \
             -if '$CreateDate' \
             -@ -
}

img_desc() {
    # Safety Check: Ensure all arguments are provided
    if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
        echo "Usage: img_desc [input_dir] [title] [keywords] "
        echo 'Example: img_desc ./input "Autumn leaves" "landscape; trees;"'
        return 1
    fi
    
	# Declare local variables
	local input=$1      # input directory
    local title=$2    	# image title
    local keywords=$3   # image keywords
	
	# Check if input directory exists
    check_dir "$input" || return 1
	
    # Proceed with function execution
    find "$input" -regextype posix-extended -type f -iregex "$regex_ext" | \
        exiftool -overwrite_original -Title="$title" -Keywords="$keywords" -@ -
}

img_gps_cp() {
    # Safety Check: Ensure all arguments are provided
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "Usage: img_gps_cp [reference_image] [input_dir]"
        echo 'Example: img_gps_cp ref.jpg ./input'
        return 1
    fi
    
	# Declare local variables
	local ref=$1      # reference image
    local input=$2    # input directory
	
	# Check if input directory exists
    check_dir "$input" || return 1
	
    # Proceed with function execution
    find "$input" -regextype posix-extended -type f -iregex "$regex_ext" | \
        exiftool -overwrite_original -tagsfromfile "$ref" -GPSLatitude* -GPSLongitude* -GPSAltitude* -@ -
}

img_dt_shift() {
    # Safety Check: Ensure required arguments are provided
    if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
        echo "Usage: img_dt_shift [input_dir] [output_dir] [+/-hh:mm:ss] [optional_new_tz_offset]"
        echo "Example: img_dt_shift ./input ./output -09:00:00"
        echo "Example (with TZ): img_dt_shift ./input ./output -09:00:00 -05:00"
        return 1
    fi
    
    # Declare local variables
    local input=$1        # input directory
    local output=$2       # output directory
    local delta=$3        # image datetime adjustment (+/-hh:mm:ss)
    local new_tz=$4       # optional explicit timezone offset (e.g., -05:00)
    
    # Check if input directory exists
    check_dir "$input" || return 1
    
    # Make the output directory if it does not exist
    mkdir -p -v "$output"
    
    # Build ExifTool offset arguments conditionally
    local tz_args=()
    if [ -n "$new_tz" ]; then
        tz_args=(
            "-OffsetTime*=${new_tz}"
        )
    fi

    # Execute transformation
    find "$input" -regextype posix-extended -type f -iregex "$regex_ext" | \
        exiftool -api QuickTimeUTC \
                 "-AllDates${delta:0:1}=${delta#[-+]}" \
                 "${tz_args[@]}" \
                 -o "$output/%f.%e" \
                 -@ -
}


img_cp() {
    # Safety Check: Ensure all arguments are provided
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "Usage: img_cp [input_dir] [output_dir]"
        echo "Example: img_cp ./input ./output"
        return 1
    fi
	
	# Declare local variables
	local input=$1		# input directory
    local output=$2		# output directory
	
	# Check if input directory exists
    check_dir "$input" || return 1
	
    # Make the output directory if it does not exist
	mkdir -p -v "$output"
	
	# Proceed with function execution
    find "$input" -regextype posix-extended -type f -iregex "$regex_ext" -exec cp -v -r -i {} "$output/" \;
}

img_rm() {
    # Safety Check: Ensure all arguments are provided
    if [ -z "$1" ]; then
        echo "Usage: img_rm [input_dir]"
        echo "Example: img_rm ./input"
        echo "WARNING: This process cannot be undone."
        return 1
    fi
    
	# Declare local variables
	local input=$1
	
	# Check if input directory exists
    check_dir "$input" || return 1
	
    # Get user confirmation
    read -p "WARNING: This process cannot be undone. Proceed? [y/N]: " choice
    
	# Proceed with function execution
    case "$choice" in 
      [yY][eE][sS]|[yY]) 
        echo "Deleting image files and empty directories from '$input' ..."
        find "$input" -regextype posix-extended -type f -iregex "$regex_ext" -exec rm -v {} \;
        find "$input" -type d -empty -delete
        ;;
      *)
        echo "Operation aborted."
        return 0
        ;;
    esac
}

img_metadata_to_csv() {
    # Safety Check: Ensure all arguments are provided
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "Usage: img_exif_to_csv [input_dir] [output_file.csv]"
        echo "Example: img_exif_to_csv ./input metadata.csv" 
        return 1
    fi
    
    # Declare local variables
    local input="$1"
    local output_csv="$2"
    
    # Check if input directory exists
    check_dir "$input" || return 1
    
    # Proceed with function execution
    echo "Extracting metadata from '$input' into '$output_csv'..."
    # -n -c "%.6f" gives signed decimal coords
	# Name all tags explicitly. Wildcards will only export tags that exist in the files.
	# GPSLatitudeRef: N, S
	# GPSLongitudeRef: E, W
	# GPSAltitudeRef: 0 = above sea level; 1 = below sea level
    find "$input" -regextype posix-extended -type f -iregex "$regex_ext" | \
        exiftool -csv -r \
        -f -api MissingTagValue="" \
		-DateTimeOriginal -Model \
        -Title -Keywords \
        -GPSLatitude -GPSLongitude -GPSAltitude \
        -n -c "%.6f" \
        -@ - > "$output_csv"

    if [ $? -eq 0 ]; then
        echo "Success! Metadata exported to $output_csv"
    else
        echo "An error occurred during extraction."
        return 1
    fi
}

# Will not work for flac; exiftool can read flac only
img_metadata_from_csv() {
    # Safety Check: Ensure required arguments are provided
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "Usage: img_exif_from_csv <input_file.csv> <target_dir>"
        echo "Example: img_exif_from_csv metadata.csv ./image_dir" 
        return 1
    fi
    
    local input_csv="$1"
    local target_dir="$2"
    
    # Check if CSV file exists
    if [ ! -f "$input_csv" ]; then
        echo "Error: Input CSV file '$input_csv' does not exist." >&2
        return 1
    fi

    # Check if target directory exists
    check_dir "$target_dir" || return 1
    
    echo "Importing metadata from '$input_csv' into '$target_dir'..."

    # Target JPEG/JPG files using native ExifTool flags
    if exiftool -csv="$input_csv" "-GPSLatitude" "-GPSLatitudeRef<GPSLatitude" "-GPSLongitude" "-GPSLongitudeRef<GPSLongitude" "-GPSAltitude" "-GPSAltitudeRef<GPSAltitude" -ext jpg -ext jpeg -overwrite_original "$target_dir"; then
        echo "Success! Metadata imported to '$target_dir'"
    else
        echo "An error occurred during metadata import." >&2
        return 1
    fi
}

img_resize() {
    # Safety Check: Ensure all arguments are provided
    if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
        echo "Usage: img_resize [input_dir] [output_dir] [new_width_px_or_%] "
        echo "Example: img_resize ./input ./output 50%"
        return 1
    fi
    
	# Declare local variables
	local input=$1
    local output=$2
    local new_width=$3
	
	# Check if input directory exists
    check_dir "$input" || return 1
	
	# Make the output directory if it does not exist
    mkdir -p -v "$output"
    
	# Proceed with function execution
	find "$input" -regextype posix-extended -type f -iregex "$regex_ext" -exec magick mogrify -path "$output" -resize "$new_width" {} +
}

img_rotate() {
    # Safety Check: Ensure all arguments are provided
    if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
        echo "Usage: img_rotate [input_dir] [output_dir] [angle_degrees] "
        echo "Example: img_rotate ./input ./output 90"
        return 1
    fi
    
	# Declare local variables
	local input=$1
    local output=$2
    local angle=$3
	
	# Check if input directory exists
    check_dir "$input" || return 1
	
	# Make the output directory if it does not exist
    mkdir -p -v "$output"
	
	# Proceed with function execution
    find "$input" -regextype posix-extended -type f -iregex "$regex_ext" -exec magick mogrify -path "$output" -rotate "$angle" {} +
}

img_tint() {
    # Safety Check: Ensure all 4 arguments are provided
    if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ]; then
        echo "Usage:   img_tint [input_dir] [output_dir] [fill_colour] [strength%]"
        echo "Example: img_tint ./input ./output \"rgb(240,200,160)\" 10%"
        return 1
    fi
	
	# Declare local variables
    local input="$1"
    local output="$2"
    local fill="$3"
    local strength="$4"

    # Check if input directory exists
    check_dir "$input" || return 1
	
	# Make the output directory if it does not exist
    mkdir -p -v "$output"
	
	# Proceed with function execution
    find "$input" -regextype posix-extended -type f -iregex "$regex_ext" \
        -exec magick mogrify -path "$output" -fill "$fill" -colorize "$strength" {} +
}

############
# Sound Functions
############

wav_to_flac() {
    # Safety Check: Ensure required arguments are provided
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "Usage: wav_to_flac <input_dir> <output_dir> [compression_level]"
        echo "Example: wav_to_flac ./input ./output 5"
        return 1
    fi
	
    local input="$1"       # Input folder
    local output="$2"      # Output folder
    local comp_level="${3:-5}" # Compression level (defaults to 5 if empty)
    
    local regex_ext='.*\.(wav|mp3)'
    mkdir -p "$output"
    while IFS= read -r -d '' f; do
        local base_name
        base_name=$(basename "$f")
        
        local pure_name="${base_name%.*}"
        
        echo "Converting: $base_name -> $pure_name.flac"
        
        # </dev/null prevents ffmpeg from greedily consuming stdin stream
        ffmpeg -i "$f" -compression_level "$comp_level" -n "$output/${pure_name}.flac" < /dev/null
    done < <(find "$input" -regextype posix-extended -type f -iregex "$regex_ext" -print0)
}

flac_create_csv_template() {
    # Safety Check: Ensure required arguments are provided
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "Usage: flac_create_csv_template <input_dir> <output_file.csv>"
        echo "Example: flac_create_csv_template ./flac_audio flac_template.csv"
        return 1
    fi
    local input_dir="$1"
    local output_csv="$2"
    check_dir "$input_dir" || return 1
    echo "Generating CSV template from FLAC files in '$input_dir' using metaflac..."
    # Write CSV Header matching requested layout
    echo "SOURCEFILE,DATETIMEORIGINAL,MODEL,SOFTWARE,TITLE,KEYWORDS,GPSLATITUDE,GPSLONGITUDE,GPSALTITUDE" > "$output_csv"
    # Find FLAC files and read existing tags using metaflac
    find "$input_dir" -type f -name "*.flac" | sort | while read -r f; do
        # Extract existing tags if present
        local dt model sw title kw lat long alt
        dt=$(metaflac --show-tag=DATETIMEORIGINAL "$f" | sed 's/^DATETIMEORIGINAL=//' | tr -d '\r')
        model=$(metaflac --show-tag=MODEL "$f" | sed 's/^MODEL=//' | tr -d '\r')
        sw=$(metaflac --show-tag=SOFTWARE "$f" | sed 's/^SOFTWARE=//' | tr -d '\r')
        title=$(metaflac --show-tag=TITLE "$f" | sed 's/^TITLE=//' | tr -d '\r')
        kw=$(metaflac --show-tag=KEYWORDS "$f" | sed 's/^KEYWORDS=//' | tr -d '\r')
        lat=$(metaflac --show-tag=GPSLATITUDE "$f" | sed 's/^GPSLATITUDE=//' | tr -d '\r')
        long=$(metaflac --show-tag=GPSLONGITUDE "$f" | sed 's/^GPSLONGITUDE=//' | tr -d '\r')
        alt=$(metaflac --show-tag=GPSALTITUDE "$f" | sed 's/^GPSALTITUDE=//' | tr -d '\r')
        # Output row with relative path
        echo "\"$f\",\"$dt\",\"$model\",\"$sw\",\"$title\",\"$kw\",\"$lat\",\"$long\",\"$alt\"" >> "$output_csv"
    done
    echo "Success! CSV import template saved to: $output_csv"
}

flac_metadata_from_csv() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "Usage: flac_metadata_from_csv <input_file.csv> <target_dir>"
        echo "Example: flac_metadata_from_csv metadata.csv ./flac_dir"
        return 1
    fi
    local input_csv="$1"
    local target_dir="$2"
    if [ ! -f "$input_csv" ]; then
        echo "Error: Input CSV file '$input_csv' does not exist." >&2
        return 1
    fi
    check_dir "$target_dir" || return 1
    local header=true
    while IFS=',' read -r sourcefile datetime device software title keywords latitude longitude altitude; do
        
        # Clean quotes, trailing spaces, and Windows line-endings (\r)
        sourcefile=$(echo "$sourcefile" | tr -d '"\r')
        datetime=$(echo "$datetime" | tr -d '"\r')
        device=$(echo "$device" | tr -d '"\r')
        software=$(echo "$software" | tr -d '"\r')
        title=$(echo "$title" | tr -d '"\r')
        keywords=$(echo "$keywords" | tr -d '"\r')
        latitude=$(echo "$latitude" | tr -d '"\r')
        longitude=$(echo "$longitude" | tr -d '"\r')
        altitude=$(echo "$altitude" | tr -d '"\r')
        if [ "$header" = true ]; then
            header=false
            continue
        fi
        [ -z "$sourcefile" ] && continue
        # Match relative file path or fallback to filename in target_dir
        local target_file="$sourcefile"
        if [ ! -f "$target_file" ]; then
            target_file="$target_dir/$(basename "$sourcefile")"
        fi
        if [ -f "$target_file" ]; then
            echo "Updating metadata for: $target_file"
            
            # Apply Vorbis tags cleanly via metaflac
            [ -n "$datetime" ]  && metaflac --remove-tag=DATETIMEORIGINAL --set-tag="DATETIMEORIGINAL=$datetime" "$target_file"
            [ -n "$device" ]    && metaflac --remove-tag=MODEL --set-tag="MODEL=$device" "$target_file"
            [ -n "$software" ]  && metaflac --remove-tag=SOFTWARE --set-tag="SOFTWARE=$software" "$target_file"
            [ -n "$title" ]     && metaflac --remove-tag=TITLE --set-tag="TITLE=$title" "$target_file"
            [ -n "$keywords" ]  && metaflac --remove-tag=KEYWORDS --set-tag="KEYWORDS=$keywords" "$target_file"
            [ -n "$latitude" ]  && metaflac --remove-tag=GPSLATITUDE --set-tag="GPSLATITUDE=$latitude" "$target_file"
            [ -n "$longitude" ] && metaflac --remove-tag=GPSLONGITUDE --set-tag="GPSLONGITUDE=$longitude" "$target_file"
            [ -n "$altitude" ]  && metaflac --remove-tag=GPSALTITUDE --set-tag="GPSALTITUDE=$altitude" "$target_file"
        else
            echo "Warning: File '$target_file' not found." >&2
        fi
    done < "$input_csv"
    echo "Metadata import completed."
}

flac_rename() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "Usage: flac_rename <input_dir> <output_dir>"
        echo "Example: flac_rename ./input ./output"
        return 1
    fi
    local input="$1"
    local output="$2"
    check_dir "$input" || return 1
    mkdir -p "$output"
    echo "Renaming FLAC files from '$input' into '$output'..."
    find "$input" -type f -name "*.flac" | while read -r f; do
        [ -f "$f" ] || continue
        # 1. Read tags from FLAC header
        local device software date_raw
        device=$(metaflac --show-tag=MODEL "$f" | sed 's/^MODEL=//' | tr -d '\r')
        software=$(metaflac --show-tag=SOFTWARE "$f" | sed 's/^SOFTWARE=//' | tr -d '\r')
        date_raw=$(metaflac --show-tag=DATETIMEORIGINAL "$f" | sed 's/^DATETIMEORIGINAL=//' | tr -d '\r')
        # Fallbacks if tags are missing
        [ -z "$device" ] && device="device"
        [ -z "$software" ] && software="app"
        if [ -z "$date_raw" ]; then
            date_raw=$(date -r "$f" +"%Y%m%d_%H%M%S")
        fi
        # 2. Sanitize text fields (lowercase, replace spaces/special chars with underscores)
        device_clean=$(echo "$device" | tr '[:upper:]' '[:lower:]' | tr ' ' '_' | sed 's/[^a-z0-9_-]//g')
        software_clean=$(echo "$software" | tr '[:upper:]' '[:lower:]' | tr ' ' '_' | sed 's/[^a-z0-9_-]//g')
        # 3. Format date to YYYYMMDD_HHMMSS (handles 2026-10-03 09:25:31 or 2026:10:03 09:25:31)
        local date_clean
        date_clean=$(echo "$date_raw" | tr -d ':-' | tr ' ' '_')
        # 4. Construct output filename: device-software-yyyymmdd_hhmmss.flac
        local new_filename="${device_clean}-${software_clean}-${date_clean}.flac"
        local dest_path="$output/$new_filename"
        echo "Copying/Renaming: $(basename "$f") -> $new_filename"
        cp "$f" "$dest_path"
    done
    echo "FLAC renaming completed successfully."
}

#########
# Video Functions
#########

vid_conv() {
    # Safety Check: Ensure all arguments are provided
    if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ]; then
        echo "Usage: vid_conv [input_video] [reference_image] [output_dir] [compression_level]"
        echo "Example: vid_conv ./input.avi ./reference.jpg ./output 20"
        return 1
    fi
	
	# Declare local variables
    local vid_in=$1         # input video
    local ref_img=$2        # reference image
    local output_dir=$3     # output directory
    local comp_level=$4     # compression level (0-51, where 0 is lossless and 51 is worst quality)

    # Strip the directory path (keep everything after the last /)
    local base=$(basename "$ref_img")

    # Strip the extension (remove everything after the last .)
    local vid_converted="${output_dir}/${base%.*}.mp4"

    # Convert the video using ffmpeg with the specified compression level and write to the same directory as the original video with the same name but .mp4 extension
    ffmpeg -i "$vid_in" -c:v libx265 -crf "$comp_level" -preset slow "$vid_converted"
    
    # Copy the GPS and creation date with time zone metadata from the reference image to the converted video using exiftool
    # exiftool -overwrite_original -tagsfromfile "$ref_img" -*date* -GPS*  "$vid_converted"

    # Copy GPS and creation date with UTC/Timezone handling using ExifTool
    exiftool -overwrite_original -api QuickTimeUTC=1 -tagsfromfile "$ref_img" \
        -Make -Model -*date* -Title -Keywords -GPS* \
        '-QuickTime:CreationDate<$DateTimeOriginal' \
        '-QuickTime:DateTimeOriginal<$DateTimeOriginal' \
        "$vid_converted"
}

vid_batch_conv() {
    # Validate that all arguments are provided and are actual directories
    if [[ -z "$vid_dir" || -z "$ref_dir" || -z "$output_dir" || -z "$comp_level" ]]; then
        echo "Usage: vid_batch_conv [input_video_dir] [reference_image_dir] [output_dir] [compression_level]" >&2
        echo "Example: vid_batch_conv ./input_vids/ ./reference_imgs/ ./output 20" >&2
        return 1
    fi
	
	# Check directories exist
    if [[ ! -d "$vid_dir" || ! -d "$ref_dir" ]]; then
        echo "Error: One or both provided paths are not valid directories." >&2
        return 1
    fi

	# Declare local variables
    local vid_dir="$1"		# input directory
    local ref_dir="$2"		# reference image directory
    local output_dir="$3"	# output directory
    local comp_level="$4" 	# compression level (0-51, where 0 is lossless and 51 is worst quality)
	
    # Read filenames into array $vid_files (ignoring directory paths, tracking only base names)
    local vid_files=()
    mapfile -t vid_files < <(find "$vid_dir" -maxdepth 1 -type f -printf '%f\n')

    # 2. Read another directory of filenames into $ref_files
    local ref_files=()
    mapfile -t ref_files < <(find "$ref_dir" -maxdepth 1 -type f -printf '%f\n')

    # Get the lengths of both arrays
    local len1=${#vid_files[@]}
    local len2=${#ref_files[@]}

    # 3. If length of $vid_files != length of $ref_files, halt and print an error message
    if (( len1 != len2 )); then
        echo "Error: Directory file counts do not match!" >&2
        echo "  First directory has $len1 files." >&2
        echo "  Second directory has $len2 files." >&2
        return 1
    else
        # 4. Else, loop through the length and convert the videos in $vid_files using the corresponding reference images in $ref_files, pairing them up by their index in the arrays
        for (( i=0; i<len1; i++ )); do
            echo "Video file:  ${vid_files[i]}  Reference file: ${ref_files[i]}"
            vid_conv "${vid_dir}/${vid_files[i]}" "${ref_dir}/${ref_files[i]}" "$output_dir" "$comp_level"
        done
    fi
}

