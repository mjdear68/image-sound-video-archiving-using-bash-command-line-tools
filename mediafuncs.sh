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

wav_create_csv_template() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "Usage: wav_create_csv_template <input_dir> <output_file.csv>"
        echo "Example: wav_create_csv_template ./wav_audio wav_template.csv"
        return 1
    fi

    local input_dir="$1"
    local output_csv="$2"

    check_dir "$input_dir" || return 1

    echo "Generating CSV template from WAV files in '$input_dir'..."

    # Write CSV Header matching exact Vorbis tag names
    echo "SourceFile,DATETIMEORIGINAL,MODEL,SOFTWARE,TITLE,KEYWORDS,LOCATION,GPSLATITUDE,GPSLONGITUDE,GPSALTITUDE" > "$output_csv"

    # Find WAV files and read existing filenames
    find "$input_dir" -type f -name "*.wav" | sort | while read -r f; do
        local datetime model software title keywords location gpslatitude gpslongitude gpsaltitude
        
        # Extract base filename without path or extension
        local pure_name
        pure_name=$(basename "$f")
        pure_name="${pure_name%.*}"

        # Construct DATETIMEORIGINAL from each file's Date Modified in format yyyy:mm:dd hh:mm:ss
        datetime=$(date -r "$f" +"%Y:%m:%d %H:%M:%S")

        # Output pure base name for robust cross-extension matching
        echo "\"$pure_name\",\"$datetime\",\"$model\",\"$software\",\"$title\",\"$keywords\",\"$location\",\"$gpslatitude\",\"$gpslongitude\",\"$gpsaltitude\"" >> "$output_csv"
    done

    echo "Success! CSV import template saved to: $output_csv"
}

wav_to_flac() {
    if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
        echo "Usage: wav_to_flac <input_dir> <output_dir> <input_csv> [compression_level]"
        echo "Example: wav_to_flac ./wav_input ./flac_output metadata.csv 5"
        return 1
    fi

    local input="$1"
    local output="$2"
    local input_csv="$3"
    local comp_level="${4:-5}"
    
    local regex_ext='.*\.(wav|mp3)'

    check_dir "$input" || return 1

    if [ ! -f "$input_csv" ]; then
        echo "Error: Input CSV file '$input_csv' does not exist." >&2
        return 1
    fi

    mkdir -p "$output"

    echo "Step 1: Converting audio files to FLAC..."
    while IFS= read -r -d '' f; do
        local base_name pure_name
        base_name=$(basename "$f")
        pure_name="${base_name%.*}"
        
        echo "Converting: $base_name -> ${pure_name}.flac"
        ffmpeg -i "$f" -compression_level "$comp_level" -n "$output/${pure_name}.flac" < /dev/null
    done < <(find "$input" -regextype posix-extended -type f -iregex "$regex_ext" -print0)

    echo "Step 2: Importing metadata from CSV to FLAC files..."
    local header=true
    
    # Store explicit Carriage Return character for safe removal
    local cr=$'\r'

    while IFS=',' read -r sourcefile datetime model software title keywords location gpslatitude gpslongitude gpsaltitude; do
        if [ "$header" = true ]; then
            header=false
            continue
        fi

        # Safely remove double-quotes and carriage returns (\r) without affecting the letter 'r'
        sourcefile="${sourcefile//[\"$cr]/}"
        datetime="${datetime//[\"$cr]/}"
        model="${model//[\"$cr]/}"
        software="${software//[\"$cr]/}"
        title="${title//[\"$cr]/}"
        keywords="${keywords//[\"$cr]/}"
		location="${location//[\"$cr]/}"
        gpslatitude="${gpslatitude//[\"$cr]/}"
        gpslongitude="${gpslongitude//[\"$cr]/}"
        gpsaltitude="${gpsaltitude//[\"$cr]/}"

        [ -z "$sourcefile" ] && continue

        # Resolve FLAC path in target output directory using base filename
        local base_source
        base_source=$(basename "$sourcefile")
        base_source="${base_source%.*}"
        
        local target_file="$output/${base_source}.flac"

        if [ -f "$target_file" ]; then
            echo "Applying Vorbis tags to: $(basename "$target_file")"
            
            [ -n "$datetime" ]    && metaflac --remove-tag=DATETIMEORIGINAL --set-tag="DATETIMEORIGINAL=$datetime" "$target_file"
            [ -n "$model" ]       && metaflac --remove-tag=MODEL --set-tag="MODEL=$model" "$target_file"
            [ -n "$software" ]    && metaflac --remove-tag=SOFTWARE --set-tag="SOFTWARE=$software" "$target_file"
            [ -n "$title" ]       && metaflac --remove-tag=TITLE --set-tag="TITLE=$title" "$target_file"
            [ -n "$keywords" ]    && metaflac --remove-tag=KEYWORDS --set-tag="KEYWORDS=$keywords" "$target_file"
			[ -n "$location" ]    && metaflac --remove-tag=LOCATION --set-tag="LOCATION=$location" "$target_file"
            [ -n "$gpslatitude" ] && metaflac --remove-tag=GPSLATITUDE --set-tag="GPSLATITUDE=$gpslatitude" "$target_file"
            [ -n "$gpslongitude" ]&& metaflac --remove-tag=GPSLONGITUDE --set-tag="GPSLONGITUDE=$gpslongitude" "$target_file"
            [ -n "$gpsaltitude" ] && metaflac --remove-tag=GPSALTITUDE --set-tag="GPSALTITUDE=$gpsaltitude" "$target_file"
        else
            echo "Warning: Target file '$target_file' not found." >&2
        fi
    done < "$input_csv"

    echo "Step 3: Renaming FLAC files using TITLE-LOCATION-%Y%m%d_%H%M%S format..."
    find "$output" -type f -name "*.flac" | while read -r f; do
        [ -f "$f" ] || continue

        local title_tag location_tag date_raw
        title_tag=$(metaflac --show-tag=TITLE "$f" | sed 's/^TITLE=//' | tr -d '\r')
        location_tag=$(metaflac --show-tag=LOCATION "$f" | sed 's/^LOCATION=//' | tr -d '\r')
        date_raw=$(metaflac --show-tag=DATETIMEORIGINAL "$f" | sed 's/^DATETIMEORIGINAL=//' | tr -d '\r')

        # Fallbacks for missing tags
        [ -z "$title_tag" ] && title_tag="Untitled"
        [ -z "$location_tag" ] && location_tag="UnknownLocation"
        if [ -z "$date_raw" ]; then
            date_raw=$(date -r "$f" +"%Y%m%d_%H%M%S")
        fi

        # Clean metadata fields for filesystem compatibility
        local title_clean location_clean date_clean
        title_clean=$(echo "$title_tag" | tr ' ' '_' | sed -E 's/[^[:alnum:]_-]//g')
        location_clean=$(echo "$location_tag" | tr ' ' '_' | sed -E 's/[^[:alnum:]_-]//g')
        
        # Format raw timestamp into %Y%m%d_%H%M%S
        date_clean=$(echo "$date_raw" | tr -d ':-' | tr ' ' '_')

        local new_filename="${title_clean}--${location_clean}--${date_clean}.flac"
        local dest_path="$output/$new_filename"

        if [ "$f" != "$dest_path" ]; then
            echo "Renaming: $(basename "$f") -> $new_filename"
            mv "$f" "$dest_path"
        fi
    done

    echo "Processing complete!"
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

