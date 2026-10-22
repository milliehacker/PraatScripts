############################################################
##    This program is free software: you can redistribute it and/or modify
##    it under the terms of the GNU General Public License as published by
##    the Free Software Foundation, either version 3 of the License, or
##    (at your option) any later version.
##
##    This program is distributed in the hope that it will be useful,
##    but WITHOUT ANY WARRANTY; without even the implied warranty of
##    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##    GNU General Public License for more details.
##
##    You should have received a copy of the GNU General Public License
##    along with this program.  If not, see <http://www.gnu.org/licenses/>.
##
##    Copyright 2011, Josef Fruehwald
##	  Additions by Jordan Kodner, 2012
##	  Style coding by Meredith Tamminga, 2013
##    Pre-pausal option by Millie Hacker, 2026
###########################################################

######################################################################################################	
##	Usage:
##		Setup
##			-- Load a long sound file and a P2FA text grid.
##			     These should be called the same thing in the objects list.
##			-- Open this script and select Run > Run
##			-- Define the segments and contexts you want to search for.
##			     Enter lists of segments separated by spaces in the context fields, or alternatively,
##			     enter "consonant" or "vowel"
##			-- Pause Threshold refers to the minimum duration of silence that constitutes a pause,
##			   e.g. when Pause Threshold is set to 0.1, only silences of at least 0.1s are considered pauses.
##		Coding
##			-- An x-word window (default 3, defined buy Window_Size) on each side of the word of interest will play twice. 
##			     You can adjust the window context and replay it within the editor, but this will require juggling
##			     between the coding window and the editor window, and will slow down your workflow.
##			-- You can enter any text into the coding field. If you are going to code multiple things, I suggest
##			     using some kind of character delimiter between codes. Use the comment field for comments to yourself.
##		Output
##			-- The output will be a tab delimited file including the following pieces of data:
##				* Object name
##				* Segment of focus
##				* Word position of the segment
##				* Code from the coding field
##				* Style lable from the style tier
##				* Time of segment start
##				* Time of segment end
##				* Time of segment end
##				* Word of focus
##				* Word start
##				* Word end
##				* Preceding segment
##				* Preceding segment start
##				* Preceding segment end
##				* Window duration
##				* Vowels per second in the window
##				* Comments
######################################################################################################	

## Largely just for my own benefit as a novice Praat scripter, I annotated most of the script with
## what I *think* each part is doing. You can tell my annotations apart from Fruehwald's, Kodner's,
## and Tamminga's because mine are messy and often express confusion :)
## ~ Millie

###############################################
#GENERATE THE STARTING MENU:
###############################################

form Search Settings

	comment File Settings
		word file speaker
			#where user enters file name
		word outfile outfile.txt
			#where user sets desired name of outfile

	comment Segments to Search For
		sentence Search_Segments IH0 NG
			#where user enters the target string(s)

	comment Word context
		optionmenu Context: 1
			option Before pause
			option Start of word
			option Word internal
			option End of word
			option Internal or End of word
			option Internal or Start of word
			option Start or End of word
			option All contexts
				#I've tried doing this with booleans (checkboxes) rather than a dropdown, but it takes up too much vertical space and Praat doesn't have an easy way to adjust that.

		sentence Pause_Threshold 0.2
			#where user sets desired pause threshold

	comment Search Context
		sentence Search_Pre_Context 
			#set requisite preceding segment(s)
		sentence Search_Post_Context
			#set requisite following segment(s)
		sentence Word_String_Search
			#I'm not sure what this does

	comment Exclusion Contexts
		sentence Stop_Pre_Context
		sentence Stop_Post_Context
		sentence Stop_Words

	comment Extra Settings
		positive Window_Size 2
		sentence Default_Code1
		sentence Default_Code2
		real Start_Time 0 
		boolean Play_on_Continue 1
endform

end_Of_Word = 0
start_Of_Word = 0
word_Internal = 0
pause_Setting = 0
	#by default, set start_Of_Word, end_Of_Word, and word_Internal to 0

#contexts are coded as numbers 1 through 7, corresponding to the Word context optionmenu above.

if context == 1
	end_Of_Word = 1
	pause_Setting = 1
elsif context == 2
	end_Of_Word = 1
elsif context == 3
	start_Of_Word = 1
elsif context == 4
	word_Internal = 1
elsif context == 5
	word_Internal = 1
	end_Of_Word = 1
elsif context == 6
	word_Internal = 1
	start_Of_Word = 1
elsif context == 7
	start_Of_Word = 1
	end_Of_Word = 1
elsif context == 8
	end_Of_Word = 1
	start_Of_Word = 1
	word_Internal = 1
endif

###############################################
#TRANSFORMING THE SEGMENT SEARCH QUERY:
###############################################

#creates array of search strings named search_array$
#length of array is num_search_segs
#creates array of lengths of search strings search_lens
#arrays indexed from 0
#see https://www.fon.hum.uva.nl/praat/manual/Regular_expressions.html

search_Segments$ = " " + replace_regex$ (search_Segments$, ",", " , ", 1000) + " , "
	#modifies the input user gave for Search Segments (e.g. IH0 NG)
	#puts a space at beginning
	#replaces all instances of "," with " , " (only relevant if searching for multiple things!)
	#adds " , " at end
	#so if user input was "IH0 NG,AH0 NG" it's modified to " IH0 NG , AH0 NG , "

search_Segments$ = replace_regex$ (search_Segments$, " +", " ", 1000)
	#modifies itself to replace all " +" with " " (up to 1000 times)
	#this just serves to delete "+" so people can use "+" instead of "," if they want

#search_Segments$ = replace_regex$ (search_Segments$, "\d", "", 1000)
	#in regex, \d stands in for any digit 0 to 9
	#modifies itself to replace digits with null
	#from prev step " IH0 NG , AH0 NG , " would become " IH NG , AH NG , "
	#this block is commented out by default, but you can take it out of comment if you want to ignore stress or dont have stress info

x = index(search_Segments$, ",")
	#define x as the first location of "," within search_Segments$
i = 0

while x > 0 && i < 15
	search_array'i'$ = left$ (search_Segments$, index(search_Segments$, ",")-1)
		#define search_array'i' as the first (location of "," in search_Segments$, minus 1) in search_Segments$
	len = length(search_array'i'$)
	if len == 3
		search_lens'i' = 1
	else
		pr$ = replace$ (search_array'i'$, " ", "", 0)
			#deletes blank spaces in search array, idk why
		search_lens'i' = length(search_array'i'$) - length(pr$) - 1
			#idk why this exists
	endif
	search_Segments$ = right$ (search_Segments$, length(search_Segments$) - index(search_Segments$, ","))
		#trim search_Segments$ to only include the rightmost (total length - position of first ",") characters
		#i.e. trims off the first ","
	i = i + 1
	x = index(search_Segments$, ",")
		#redefine x as the position of the next leftmost remaining ","
		#if there are no commas left, x no longer > 0 and the loop ends
endwhile
num_search_segs = i-1
	#num_search_segs corresponds to the number of times the loop re-iterated

#log_file = file$ + ".log"

###############################################
#DEFINING PRE AND POST CONTEXTS AND EXCLUSIONS:
###############################################

vowel$ = " AA AE AH AO AW AX AY EH EY IH IY OW OY UH UW "
consonant$ = " B CH DH DX AXR EL EM EN ER F G HH HV JH K L M N NX NG P R S SH T TH V W Y Z ZH "

if index(search_Pre_Context$,"vowel") > 0
	#if there exists the term "vowel" in the user-specified search_Pre_Context...
	search_Pre_Context$ = vowel$
		#then set search_Pre_Context$ to the long string containing all the vowels
elsif index(search_Pre_Context$, "consonant") > 0
	search_Pre_Context$ = consonant$
else
	search_Pre_Context$ = " "+search_Pre_Context$+" "
		#adds two blank spaces to the ends of search_Pre_Context for some reason
endif

if index(search_Post_Context$,"vowel") > 0
	search_Post_Context$ = vowel$
elsif index(search_Post_Context$ ,"consonant") > 0
	search_Post_Context$ = consonant$
else
	search_Post_Context$ = " "+search_Post_Context$+" "
endif

if index(stop_Pre_Context$, "vowel") >0
	stop_Pre_Context$ = vowel$
elsif index(stop_Pre_Context$ ,"consonant") >0
	stop_Pre_Context$ = consonant$
else
	stop_Pre_Context$ = " "+stop_Pre_Context$+" "
endif

if index(stop_Post_Context$, "vowel") > 0
	stop_Post_Context$ = vowel$
elsif index(stop_Post_Context$, "consonant") > 0
	stop_Post_Context$ = consonant$
else
	stop_Post_Context$ = " "+stop_Post_Context$+" "
endif

stop_Words$ = " "+stop_Words$+" "

###############################################
#START LOOKING AT THE TEXTGRID:
###############################################

select TextGrid 'file$'
plus LongSound 'file$'
	#plus function selects the two together

Edit
editor TextGrid 'file$'
endeditor
	#I don't really get why the editor gets opened just to be closed again, but messing with this seems to break everything

select TextGrid 'file$'

if start_Time == 0
	fileappend 'outfile$'	File	Segment	Position	Code1	Code2	Style	Seg_Start	Seg_End	Word	Word_Start	Word_End	Pre_Seg	Pre_Seg_Start	Pre_Seg_End	Post_Seg	Post_Seg_Start	Post_Seg_End	Window	Vowels_per_Second	Comments	Warnings'newline$'
		#writes the header of the outfile as a tab-separated csv
endif
		
		# gets number of style tier
		style_TierNum = 0
		num = Get number of tiers
		for i from 1 to num
			currentTier$ = Get tier name... i 
			if currentTier$ = "style"
				style_TierNum = i
			endif
		endfor
			#I don't think this applies unless the textgrid you go in with already has a "style" tier

		word_Intervals = Get number of intervals... 1
			#gets number of word intervals (corresponding to tier 1)
		start_Interval = Get interval at time... 1 start_Time
			#gets interval to be used in following loop (tier 1)
		for int from start_Interval to word_Intervals
			word$ = Get label of interval... 1 int
				#gets the current word (the int'th interval on tier 1)
			word_Start = Get start point... 1 int
				#gets the start point of the word (the int'th interval on tier 1)
			word_End = Get end point... 1 int
				#gets the end point of the word (the int'th interval on tier 1)

			foundPause = 0
				#by default, assume no pause was found
			nextWord$ = ""
			nextWord$ = Get label of interval... 1 int+1
			if nextWord$ == ""
					#if the next word is a blank block...
				nextStart = Get start point... 1 int+1
				nextEnd = Get end point... 1 int+1
				nextDur = nextEnd-nextStart
				if nextDur > number(pause_Threshold$)
					foundPause = 1
						#...and the blank block's duration exceeds the specified pause threshold, then a pause has been found!
				endif
			elsif nextWord$ == "{br}"
				foundPause = 1
					#a word directly followed by a breath is counted as pre-pausal by default.
					#feel free to delete this part if u dont like it, u won't break anything.
			endif
		
			if index(stop_Words$, " "+word$+" ") == 0
			#Only do the following if the word isn't in the list of Exclusion words...

				#styleInt = Get interval at time... style_TierNum word_End - 0.005
				#style$ = Get label of interval... style_TierNum styleInt
					#only relevant if u have a style tier

				ph_First_Int = Get interval at time... 2 word_Start + 0.005
					#from phone tier (tier 2), get the interval at 5ms after word_start time (THE FIRST PHONE IN THE WORD)
				ph_Last_Int = Get interval at time... 2 word_End - 0.005			
					#get the last phone in the word	

				#
				# stores Arpabet transcription of word as arpa$
				arpa$ = ""

				for ph_Int from ph_First_Int to ph_Last_Int
					seg$ = Get label of interval... 2 ph_Int
					arpa$ = arpa$ + seg$ + " "
						#uses a loop to build the word's arpabet representation piece by piece
				endfor

				#arpa$ = replace_regex$ (arpa$, "\d", "", 0)
					#use this to optionally omit stress representations

				for ph_Int from ph_First_Int to ph_Last_Int
					#within a given word, loop through its phones

					seg$ = Get label of interval... 2 ph_Int
						#get the phone in the current iteration of the loop

					#checks whether this word contains search terms

					#condition_met: ~(whether a search segment was found)
					#found_len: length of search segment matched
					#found_index: index of search segment matched in search_array$

					condition_met = 1
					found_len = 0
					found_index = 0
					arpa$ = " " + arpa$

					for i from 0 to num_search_segs
					#for each segment in the query:
						if index_regex (arpa$, search_array'i'$) == 1
						#if the query's first segment is in the current word:
							condition_met = 0
							found_len = search_lens'i'
							found_index = i
								#...store the index of a successfully identified phone
						endif
					endfor
					arpa$ = right$ (arpa$, length(arpa$) -1)
						#delete the first character from the arpabet representation
					arpa$ = right$ (arpa$, length(arpa$) - index(arpa$, " "))
						#deletes an extra space from the left edge of the arpabet representation (?)

					if condition_met = 0
				
						seg_Start = Get start point... 2 ph_Int
							#pull starttime of the local phone
						seg_End = Get end point... 2 ph_Int
							#pull endtime of the local phone
						seg_Dur = seg_End-seg_Start
							#calculate duration of the local phone
						seg_Mid = seg_Start + (seg_Dur/2)
							#calculate midpoint of the local phone

						if ph_Int > 1
						#i.e. if it's not the first phone in the word...
							pre_Seg$ = Get label of interval... 2 ph_Int-1
							#store the previous interval label as pre_Seg$
						else
							pre_Seg$ = "none"
								#set pre_Seg$ to "none" if it's the first phone in the word
						endif

						pre_Seg$ = replace$(pre_Seg$, "0", "", 0)
						pre_Seg$ = replace$(pre_Seg$, "1", "", 0)
						pre_Seg$ = replace$(pre_Seg$, "2", "", 0)
							#remove stress information from pre_Seg$

						post_Seg$ = Get label of interval... 2 ph_Int+found_len
							#I don't understand how found_len is relevant here (why can't it just be ph_Int+1?) but basically defines the following segment
						post_Seg$ = replace$(post_Seg$, "0", "", 0)
						post_Seg$ = replace$(post_Seg$, "1", "", 0)
						post_Seg$ = replace$(post_Seg$, "2", "", 0)
							#remove stress information from post_Seg$

						location$ = ""

						if end_Of_Word == 1 and ph_Int + found_len -1 == ph_Last_Int
							condition_met = 1
							location$ = "End"
						endif
							#determines whether it's the end of the word

						if start_Of_Word == 1 and ph_Int == ph_First_Int
							condition_met = 1
							location$ = "Start"
						endif
							#determines whether it's the start of the word

						if word_Internal == 1 and ph_Int <> ph_First_Int and ph_Int <> ph_Last_Int
							condition_met = 1
							location$ = "Internal"
						endif
							#determines whether it's word-internal

						if length(replace$ (search_Pre_Context$, " ", "", 0)) > 0 and found_len == 1
							if index(search_Pre_Context$, " "+pre_Seg$+" ") == 0
				 				condition_met = 0
							endif
						endif

						if length(replace$ (search_Post_Context$, " ", "", 0)) > 0 and found_len == 1
							if index(search_Post_Context$, " "+post_Seg$+" ") == 0
								condition_met = 0
							endif
						endif

						if length(replace$ (stop_Pre_Context$, " ", "", 0)) > 0 and found_len == 1
							if index(stop_Pre_Context$, " "+pre_Seg$+" ") > 0
								condition_met = 0
							endif
						endif

						if length(replace$ (stop_Post_Context$, " ", "", 0)) > 0
							if index(stop_Post_Context$, " "+post_Seg$+" ") > 0
								condition_met = 0
							endif
						endif
							#I think the above four conditional blocks are to instantiate exclusion contexts

						if pause_Setting == 1
							if foundPause == 0
								condition_met = 0
							endif
						endif
							#if looking for pre-pausal and there was no pause found, skip the word

###############################################
#OPEN THE PLAY WINDOW:
###############################################

						if condition_met == 1
							window_Start = Get start point... 1 max(1,int - window_Size)
							window_End = Get end point... 1 min(int + window_Size, word_Intervals)
							window_Dur = window_End - window_Start
								#sets the window size by taking the range of current interval and building a buffer on each side corresponding to the user-set window_Size specification

							firstPhInt = Get interval at time... 2 window_Start+0.005
							lastPhInt = Get interval at time... 2 window_End-0.005
								#I'm not sure yet why it's storing the first and last phones in the window but whatevah

							nval = 0
							sp_Dur = 0
							for ph from firstPhInt to lastPhInt
								phLabel$ = Get label of interval... 2 ph
								if endsWith (phLabel$, "0") or endsWith (phLabel$, "1") or endsWith (phLabel$, "2")
									nval = nval + 1
										#increment nval if there is stress information in the phone
										#I think this is serving as a proxy for vowel/consonant distinction
								elsif phLabel$ = "sp"
									ph_Start = Get start point... 2 ph
									ph_End = Get end point... 2 ph
									spDur = sp_Dur + (ph_End - ph_Start)
										#???
								endif
							endfor
							real_Dur = window_Dur - sp_Dur
								#I don't know why real_Dur is calculated this way, or if it's even going to be used in the output segment duration
							vowels_Per_Second = nval / (window_Dur - sp_Dur)
								#uses nval (the number of vowels in the window) to calculate speech rate
				
							pre_Seg_Start = Get start point... 2 ph_Int-1
							pre_Seg_End = Get end point... 2 ph_Int-1
							pre_Seg_Dur = pre_Seg_End - pre_Seg_Start
								#timing info of preceding segment

							post_Seg_Start = Get start point... 2 ph_Int+found_len
							post_Seg_End = Get end point... 2 ph_Int+found_len
							post_Seg_Dur = post_Seg_End - post_Seg_Start
								#timing info of following segment


###############################################
#OPEN THE CODING MENU FOR THE HUMAN ANNOTATOR:
###############################################

							editor TextGrid 'file$'
							Zoom... max(1,window_Start) min(window_End, word_Intervals)
								#finds new window info for next play cycle
							if play_on_Continue = 1
								Play window
							endif

							coded = 0
							
							while coded == 0
							beginPause ("Code it")
								comment("'word$' 'location$'")
								comment("Code 1")
								text ("code1", default_Code1$)
								comment("Code 2")
								text ("code2", default_Code1$)
								comment("Comments")
								text ("comment", "")
								comment("Preceding Segment")
								text("Preceding_Segment", pre_Seg$)
								comment("Following Segment")
								text("Following_Segment", post_Seg$)
								comment("Reject this token?")
								boolean("Reject", 0)
							#	Play window
							click = endPause ("Play", "Continue", 2)
							if click == 1
								Play window
							else
								coded = 1
							endif
							endwhile

							endeditor
							warning$ = ""
							if preceding_Segment$ <> pre_Seg$
								warning$ = "PreSeg Changed"
								pre_Seg$ = preceding_Segment$
							endif
								#puts a warning line in the output file if actual preseg observed by user differs from what was in the original textgrid

							if following_Segment$ <> post_Seg$
								warning$ = "PostSeg Changed"
								post_Seg$ = following_Segment$
							endif
								#puts a warning line in the output file if actual postseg observed by user differs from what was in the original textgrid

							if reject ==0
								#(as long as the token wasn't rejected)
								fileappend 'outfile$'	'file$'	'seg$'	'location$'	'code1$'	'code2$'	'style$'	'seg_Start:3'	'seg_End:3'	'word$'	'word_Start:3'	'word_End:3'	'pre_Seg$'	'pre_Seg_Start:3'	'pre_Seg_End:3'	'post_Seg$'	'post_Seg_Start:3'	'post_Seg_End:3'	'real_Dur:3'	'vowels_Per_Second:3'	'comment$'	'warning$''newline$'
							endif
						endif		
					endif
				endfor
			endif
		endfor