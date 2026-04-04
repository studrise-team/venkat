import re
from typing import List, Dict, Any


def parse_mcq_from_text(text: str) -> List[Dict[str, Any]]:
    """
    Phase 4: Regex-based MCQ parser.

    Supports formats like:
        1. Question text?
        A) Option 1
        B) Option 2
        C) Option 3
        D) Option 4
        Answer: B
    """
    results = []

    # Split text into question blocks on numbered lines
    blocks = re.split(r'\n(?=\s*\d+[\.\)])', text.strip())

    for block in blocks:
        block = block.strip()
        if not block:
            continue

        lines = [l.strip() for l in block.split('\n') if l.strip()]
        if len(lines) < 5:
            continue

        # Extract question (first line, strip leading number)
        question_line = re.sub(r'^\d+[\.\)]\s*', '', lines[0]).strip()
        if not question_line:
            continue

        # Extract options A-D
        options = []
        answer_text = ''
        answer_idx = -1

        for line in lines[1:]:
            opt_match = re.match(r'^[A-Da-d][\.\)]\s*(.+)', line)
            if opt_match:
                options.append(opt_match.group(1).strip())

            ans_match = re.search(
                r'[Aa]ns(?:wer)?\s*[:\-]?\s*([A-Da-d])', line
            )
            if ans_match:
                letter = ans_match.group(1).upper()
                answer_idx = ord(letter) - ord('A')

        if len(options) != 4:
            continue

        if 0 <= answer_idx < len(options):
            answer_text = options[answer_idx]
        else:
            answer_text = options[0]  # default first if not found

        results.append({
            'question': question_line,
            'options': options,
            'answer': answer_text,
        })

    return results
