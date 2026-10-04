"""Reproducible offline audio build entrypoint.

See AUDIO_SOURCES.md for source-cache preparation and verified provenance.
Approved sand plus five owner-supplied WAVs are protected by byte hashes.
"""
from render_audio_score import main


if __name__ == "__main__":
    main()
