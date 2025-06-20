import difflib

def calculate_score(original, corrected):
    sm = difflib.SequenceMatcher(None, original.strip(), corrected.strip())
    return round(sm.ratio() * 100, 2)
