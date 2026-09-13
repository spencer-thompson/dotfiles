---
name: unslop
description: Edit supplied writing to remove formulaic AI phrasing while preserving meaning and the author's voice. Use when explicitly invoked.
---

# Unslop

Edit the requested text for clear, natural writing. Apply this skill to the requested editing task, not automatically
to later responses or unrelated communication. Preserve meaning, factual uncertainty, technical precision, quotations,
and the author's intended tone.

## Process

1. Scan for the patterns below.
2. Rewrite. Preserve meaning, match intended tone.
3. Check that the revision is clearer and still says what the author intended.

## Preserve voice

Keep the author's opinions, personality, and natural rhythm. Do not invent feelings, personal experiences, opinions,
or deliberate disorder to make text seem human. Preserve neutral comparison when it serves the task. Use first person
when it matches the author and context, and add specificity only when supported by the source material.

## Patterns to detect and fix

Treat these as editing cues, not banned words or mandatory transformations. Change a pattern when it weakens this text.
Preserve accurate terminology and intentional formatting; follow the user's style requirements when they differ.

### Content

1. **Puffery.** "pivotal moment", "testament to", "evolving landscape", "setting the stage for", "indelible mark",
   "deeply rooted". Cut puffery, state what happened.
2. **Name-dropping.** Listing media outlets without context. Pick one, say what was said.
3. **Superficial -ing phrases.** "highlighting...", "ensuring...", "reflecting...", "showcasing...", "fostering...".
   Delete or expand with real sources.
4. **Promotional language.** "nestled", "vibrant", "breathtaking", "groundbreaking", "renowned", "stunning",
   "must-visit". Use neutral descriptions.
5. **Vague attributions.** "Experts believe", "Industry reports suggest", "Some critics argue". Name the source or
   delete.
6. **Formulaic challenges.** "Despite challenges... continues to thrive." Replace with specific facts.

### Language

7. **Inflated vocabulary.** Words such as "delve", "pivotal", and abstract "tapestry" can add ceremony without meaning.
   Prefer a plain equivalent when it is equally precise; do not replace useful terms just because they appear on a list.
8. **Fancy ways to say "is".** "serves as", "stands as", "boasts", "features". Just say "is" or "has".
9. **"Not just X, but Y."** State the point directly instead.
10. **Rule of three.** Forcing ideas into groups of three. Use the natural number.
11. **Synonym cycling.** Protagonist, main character, central figure, hero all in one paragraph. Pick one, repeat it.
12. **False ranges.** "from X to Y" where X and Y aren't on a meaningful scale. List topics directly.

### Style

13. **Punctuation habits.** Reduce repeated dashes or parenthetical asides when they interrupt the flow. Keep
    punctuation that clarifies the sentence, including parentheses, ranges, and technical notation.
14. **Colon overuse.** Use colons when they introduce or explain something clearly. Rewrite awkward connectors instead
    of mechanically swapping punctuation.
15. **Boldface overuse.** Don't bold every proper noun or acronym.
16. **Inline-header lists.** The tell is a bold label and colon that restates the line: "**Performance:** Performance
    improved...". Convert those to prose. A bold lead-in that ends in a period, names the item, and is followed by
    genuinely new detail ("**Schema in TypeScript.** Tables live in one file.") is fine, not a tell.
17. **Heading case.** Prefer sentence case unless the publication or author's style calls for another convention.
18. **Decorative emojis.** Remove distracting decoration; keep intentional, sparing use that fits the tone.
19. **Quote style.** Preserve the document's consistent typography. Use straight quotes where required by code or the
    output format.

### Communication artifacts

20. **Chatbot phrases.** "I hope this helps!", "Let me know if...", "Of course!", "Certainly!", "Found the smoking gun!"
    Remove.
21. **Vague disclaimers.** Replace "While specific details are limited..." with the actual limitation. Preserve
    uncertainty that affects the claim; do not invent sources or certainty.
22. **Sycophantic tone.** "Great question! You're absolutely right!" Respond directly.

### Filler

23. **Filler phrases.** "In order to" becomes "To". "Due to the fact that" becomes "Because". "It is important to note
    that" gets deleted.
24. **Excessive hedging.** "could potentially possibly be argued that it might" becomes "may".
25. **Generic conclusions.** "The future looks bright." State specific plans or facts.

### Jargon

26. **Abstract metaphors.** Replace vague metaphors with the actual mechanism when that improves understanding.
    "Evacuate the code" can be "move the code"; explain what a metaphorical "flywheel" actually does. Keep precise
    technical terms such as "vector", "primitive", or "API surface" when they carry the intended meaning.

### Plain speech

27. **Say what it does, not how it feels.** "the database stays close at hand", "SQL you can read", "types that follow
    your schema" name a feeling. The fix names the mechanism or a number: "`.toSQL()` returns the exact string sent to the
    database", "a column rename fails the build". Ask what the sentence tells the reader to do or know, then write that.
    Prefer supported mechanisms and examples in technical explanations. Keep emotional language or general guidance when
    it serves the author's purpose; do not invent specificity or delete useful context merely because it is reusable.
28. **Shorten or split dense sentences.** If the reader has to backtrack to parse a sentence, break it in two or drop
    clauses. One idea per sentence.
29. **Active voice.** Prefer it. Catch "is/are/was/were + past participle" and name the actor: "queries are validated"
    becomes "the compiler validates queries", "the file is parsed by the loader" becomes "the loader parses the file".
    Passive is fine only when the actor is unknown or genuinely doesn't matter.
30. **Cut adverbs, or use a stronger verb.** "runs quickly" becomes "is fast" or the number. "significantly improves"
    becomes the measured delta. An adverb propping up a weak verb means the verb is wrong.
31. **Prefer the plain word.** "utilize" becomes "use", "leverage" becomes "use", "facilitate" becomes "help",
    "numerous" becomes "many", "in the event that" becomes "if". The fancier synonym is rarely clearer.
