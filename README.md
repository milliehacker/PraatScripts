------------------------------------------------------------------

General Handcoder info:

The Praat Handcoder is a flexible Praat script used for manual coding of phonetic data given a pre-existing textgrid and audio file.

Running the Handcoder generates a form where you build a query of the type of data you’re looking for. You simply tell the Handcoder the segments (or sequences of segments) you want, and the contexts you’re looking for them in.

For example, your query could be “Show me all the IH0 NG and L IY0 at the end of words, but skip ones that are preceded by T or D.”

Note that phonetic representations of words and segments must in ARPABET, not IPA, because the Handcoder is designed to operate on MFA-aligned textgrids.

The Handcoder then takes you to each part of your textgrid that matches your query, plays the corresponding audio, and invites you to enter codes based on what you heard.

Your codes, as well as info about the token's context, are written to a tsv-formatted text file.

See comments in HandCoderPauseMod.praat for more info.

The original version of the Praat handcoder by Joe Fruehwald can be found here: https://github.com/JoFrhwld/FAAV/blob/master/praat/handCoder.praat

I haven’t been able to find Jordan Kodner’s or Meredith Tamminga’s versions uploaded anywhere on the web. Tamminga’s version was shared with me directly by a colleague.

------------------------------------------------------------------

Pause mod:

This Handcoder mod adds a “Before pause” context, which is potentially of use to (socio)phoneticians because following pauses are known to influence the likelihood of certain word-final phonetic and phonological processes occurring. They are also known to influence the salience of sociolinguistic variables by, for example, making stop releases more perceptible.

When the context is set to “Before pause”, the script skips over all words that are not followed by a blank interval in the textgrid.

You can adjust the "Pause Threshold" to change how long of a blank interval constitutes a true pause for your specific research question (the expected duration of a pause differs substantially in different situations.) For example, if Pause Threshold is set to 0.3, then blank intervals of less than 300ms will be skipped.

As I've written it, any interval occupied by {br} (breath) counts as a pause. If you don't want to include breaths as pauses, just search for {br} in the script and you'll find the relevant elsif condition. You can safely delete the whole elsif without impacting the rest of the script.

IMPORTANT DISCLAIMER: Because this method is based on the duration of textgrid intervals, the accuracy of pause identification is entirely dependent on the accuracy of your alignment. You will get false positives if you have blank intervals concurrent with speech, and you will get false negatives if you have annotated intervals concurrent with silence.

------------------------------------------------------------------

Please feel free to reach out to me with any questions at hackermi (at) msu (dot) edu
