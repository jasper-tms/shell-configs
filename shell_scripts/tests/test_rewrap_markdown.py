#!/usr/bin/env python3
"""
Tests for shell_scripts/rewrap-markdown and the pre-commit hook that runs it
(git-hooks/pre-commit.d/10-rewrap-skill-markdown.sh).

Run with:
    python3 shell_scripts/tests/test_rewrap_markdown.py
"""
import importlib.machinery
import importlib.util
import os
import subprocess
import sys
import tempfile
import textwrap
import unittest
from pathlib import Path

TESTS_FOLDER = Path(__file__).resolve().parent
SCRIPT = TESTS_FOLDER.parent / 'rewrap-markdown'
HOOK = (TESTS_FOLDER.parent.parent / 'git-hooks' / 'pre-commit.d'
        / '10-rewrap-skill-markdown.sh')

# The script has no .py extension, so load it explicitly.
loader = importlib.machinery.SourceFileLoader('rewrap_markdown', str(SCRIPT))
specification = importlib.util.spec_from_loader('rewrap_markdown', loader)
rewrap_markdown = importlib.util.module_from_spec(specification)
loader.exec_module(rewrap_markdown)

LONG = ' '.join(['word'] * 17)


def markdown(text):
    """Dedent a triple-quoted test document and drop its leading newline."""
    return textwrap.dedent(text).lstrip('\n')


def rewrap(text, lines=None, width=79):
    """Re-wrap `text`, optionally only the paragraphs on these 1-based lines."""
    return rewrap_markdown.rewrap_text(
        text, width, None if lines is None else set(lines))


class RewrapTestCase(unittest.TestCase):
    def assertRewrapsTo(self, original, expected, lines=None, width=79):
        self.assertEqual(rewrap(original, lines, width), expected)

    def assertUnchanged(self, original, lines=None, width=79):
        self.assertEqual(rewrap(original, lines, width), original)


class TestParagraphs(RewrapTestCase):
    def test_long_line_is_wrapped_under_80_columns(self):
        result = rewrap('start ' + LONG + ' ' + LONG + '\n')
        for line in result.splitlines():
            self.assertLessEqual(len(line), 79)

    def test_short_lines_are_joined(self):
        self.assertRewrapsTo('one\ntwo\nthree\n', 'one two three\n')

    def test_well_wrapped_paragraph_is_unchanged(self):
        self.assertUnchanged(markdown('''
            The quick brown fox jumps over the lazy dog, and then it keeps on running
            through the field until it reaches the river at the edge.
            '''))

    def test_line_of_exactly_79_characters_is_kept(self):
        line = 'a' * 75 + ' bcd'
        self.assertEqual(len(line), 79)
        self.assertUnchanged(line + '\n')

    def test_line_of_80_characters_is_wrapped(self):
        self.assertRewrapsTo('a' * 75 + ' bcde\n', 'a' * 75 + '\nbcde\n')

    def test_custom_width(self):
        self.assertRewrapsTo('a b c d e f g h\n', 'a b c\nd e f\ng h\n',
                             width=5)

    def test_word_too_long_for_any_line_gets_its_own_line(self):
        url = 'https://example.com/' + 'x' * 80
        self.assertRewrapsTo(f'See {url} now\n', f'See\n{url}\nnow\n')

    def test_repeated_spaces_collapse(self):
        self.assertRewrapsTo('one   two\n', 'one two\n')

    def test_paragraphs_stay_separate(self):
        self.assertUnchanged('one\n\ntwo\n')

    def test_whitespace_only_line_becomes_empty(self):
        self.assertRewrapsTo('one\n   \ntwo\n', 'one\n\ntwo\n')

    def test_missing_final_newline_is_preserved(self):
        self.assertRewrapsTo('one\ntwo', 'one two')

    def test_windows_line_endings_are_preserved(self):
        self.assertRewrapsTo('one\r\ntwo\r\n', 'one two\r\n')

    def test_wide_characters_count_as_two_columns(self):
        result = rewrap(' '.join(['日本語'] * 14) + '\n')
        for line in result.splitlines():
            self.assertLessEqual(rewrap_markdown.display_width(line), 79)
        self.assertEqual(len(result.splitlines()), 2)


class TestInlineSpans(RewrapTestCase):
    def test_code_span_is_kept_whole_when_little_space_is_left(self):
        # Moving the span to the next line leaves 17 empty columns.
        span = '`one two three four five six seven eight nine ten`'
        self.assertRewrapsTo('a' * 62 + ' ' + span + ' end\n',
                             'a' * 62 + '\n' + span + ' end\n')

    def test_code_span_is_broken_when_a_lot_of_space_is_left(self):
        # Moving the span to the next line would leave 39 empty columns.
        span = '`one two three four five six seven eight nine ten`'
        self.assertRewrapsTo(
            'a' * 40 + ' ' + span + ' end\n',
            'a' * 40 + ' `one two three four five six seven\neight nine ten`'
            ' end\n')

    def test_link_is_kept_whole_when_little_space_is_left(self):
        link = '[the long docs page](https://x.io/a)'
        self.assertRewrapsTo('a' * 64 + ' ' + link + ' please.\n',
                             'a' * 64 + '\n' + link + ' please.\n')

    def test_reference_link_is_kept_whole_when_little_space_is_left(self):
        link = '[the long docs page][label]'
        self.assertRewrapsTo('a' * 70 + ' ' + link + ' please.\n',
                             'a' * 70 + '\n' + link + ' please.\n')

    def test_code_span_too_long_for_any_line_is_broken(self):
        # Breaking a code span at a space renders identically, so it is
        # allowed when the span cannot fit on a line of its own.
        span = '`' + ' '.join(['code'] * 20) + '`'
        result = rewrap(span + '\n')
        for line in result.splitlines():
            self.assertLessEqual(len(line), 79)
        self.assertEqual(' '.join(result.split()), span)

    def test_inline_html_tag_is_not_broken(self):
        tag = '<a href="https://example.com/page" title="a title">'
        result = rewrap('a' * 50 + ' ' + tag + 'link</a>\n')
        self.assertIn(tag, result)

    def test_backslash_escaped_space_is_not_a_break(self):
        result = rewrap('a' * 70 + ' one\\ two\n')
        self.assertIn('one\\ two', result)

    def test_link_is_broken_when_a_lot_of_space_is_left(self):
        self.assertRewrapsTo(
            'Read [the long documentation page]'
            '(https://example.com/some/really/long/path/here) please.\n',
            'Read [the long documentation\n'
            'page](https://example.com/some/really/long/path/here) please.\n')


class TestBlockStartingWords(RewrapTestCase):
    """A wrapped line must never start with something that opens a block."""

    def check_word_is_not_at_line_start(self, word):
        filler = ' '.join(['abcd'] * 15)
        result = rewrap(f'{filler} {word} after\n')
        for line in result.splitlines()[1:]:
            self.assertFalse(line.startswith(word + ' '),
                             f'{word!r} starts a line in:\n{result}')
        self.assertEqual(result.split(), f'{filler} {word} after'.split())

    def test_dash(self):
        self.check_word_is_not_at_line_start('-')

    def test_plus(self):
        self.check_word_is_not_at_line_start('+')

    def test_asterisk(self):
        self.check_word_is_not_at_line_start('*')

    def test_number_with_period(self):
        self.check_word_is_not_at_line_start('302.')

    def test_number_with_parenthesis(self):
        self.check_word_is_not_at_line_start('1)')

    def test_heading_marker(self):
        self.check_word_is_not_at_line_start('#')

    def test_quote_marker(self):
        self.check_word_is_not_at_line_start('>quote')

    def test_pipe(self):
        self.check_word_is_not_at_line_start('|')

    def test_html_tag(self):
        self.check_word_is_not_at_line_start('<div>')

    def test_unavoidable_block_start_leaves_an_overlong_line(self):
        self.assertRewrapsTo('a' * 78 + ' - x\n', 'a' * 78 + ' -\nx\n')


class TestListsQuotesAndFootnotes(RewrapTestCase):
    def test_bullet_item_continuation_is_indented(self):
        self.assertRewrapsTo(
            f'- top item {LONG}\n',
            '- top item word word word word word word word word word word '
            'word word word\n  word word word word\n')

    def test_nested_list_items(self):
        result = rewrap(f'- top {LONG}\n  - nested {LONG}\n    more\n')
        lines = result.splitlines()
        self.assertTrue(lines[0].startswith('- top'))
        self.assertTrue(lines[1].startswith('  word'))
        self.assertTrue(lines[2].startswith('  - nested'))
        self.assertTrue(all(line.startswith('    ') for line in lines[3:]))
        self.assertTrue(result.rstrip().endswith('more'))

    def test_ordered_list_continuation_aligns_with_text(self):
        result = rewrap(f'1. first {LONG}\n2. second\n')
        self.assertEqual(result.splitlines()[1][:4], '   w')
        self.assertTrue(result.splitlines()[2].startswith('2. second'))

    def test_list_items_are_not_merged(self):
        self.assertUnchanged('- one\n- two\n- three\n')

    def test_task_list_item(self):
        result = rewrap(f'- [ ] task {LONG}\n')
        self.assertTrue(result.startswith('- [ ] task'))
        self.assertTrue(result.splitlines()[1].startswith('  word'))

    def test_block_quote(self):
        result = rewrap(f'> quoted {LONG}\n> more quoted\n')
        self.assertTrue(all(line.startswith('> ')
                            for line in result.splitlines()))
        self.assertTrue(result.rstrip().endswith('more quoted'))

    def test_nested_block_quote(self):
        result = rewrap(f'> > deep {LONG}\n')
        self.assertTrue(all(line.startswith('> > ')
                            for line in result.splitlines()))

    def test_footnote_continuation_is_indented_four(self):
        result = rewrap(f'[^1]: footnote {LONG}\n')
        self.assertTrue(result.startswith('[^1]: footnote'))
        self.assertTrue(result.splitlines()[1].startswith('    word'))

    def test_wrapped_number_continues_the_paragraph(self):
        # "302." at the start of a continuation line cannot start a list,
        # since only an item numbered 1 can interrupt a paragraph.
        self.assertRewrapsTo('There were\n302. of them\n',
                             'There were 302. of them\n')


class TestHardLineBreaks(RewrapTestCase):
    def test_two_trailing_spaces(self):
        self.assertRewrapsTo(
            f'line one is here  \nline two {LONG}\n',
            'line one is here  \nline two ' + ' '.join(['word'] * 14) + '\n'
            'word word word\n')

    def test_trailing_backslash(self):
        result = rewrap(f'line one\\\nline two {LONG}\n')
        self.assertTrue(result.startswith('line one\\\nline two'))

    def test_single_trailing_space_is_not_a_hard_break(self):
        self.assertRewrapsTo('word \nnext\n', 'word next\n')


class TestVerbatimBlocks(RewrapTestCase):
    def test_front_matter(self):
        self.assertUnchanged(f'---\nname: x\ndescription: {LONG} {LONG}\n'
                             '---\n\nbody\n')

    def test_front_matter_with_body_rewrap(self):
        result = rewrap(f'---\ndescription: {LONG} {LONG}\n---\nbody {LONG}'
                        f' {LONG}\n')
        self.assertIn(f'description: {LONG} {LONG}\n', result)

    def test_fenced_code_block(self):
        self.assertUnchanged(f'```\n{LONG} {LONG}\nshort\nlines\n```\n')

    def test_tilde_fenced_code_block(self):
        self.assertUnchanged(f'~~~python\n{LONG} {LONG}\nx\n~~~\n')

    def test_fence_inside_list_item(self):
        self.assertUnchanged(f'- item\n\n  ```\n  {LONG} {LONG}\n  x\n  ```\n')

    def test_indented_code_block(self):
        self.assertUnchanged(f'Text.\n\n    {LONG} {LONG}\n    short\n')

    def test_math_block(self):
        self.assertUnchanged(f'$$\na {LONG} {LONG}\nb\n$$\n')

    def test_heading(self):
        self.assertUnchanged(f'# Heading {LONG} {LONG}\n')

    def test_setext_heading(self):
        self.assertUnchanged(f'Title {LONG} {LONG}\n===\n')

    def test_table(self):
        self.assertUnchanged(f'| a | b |\n|---|---|\n| {LONG} {LONG} | x |\n')

    def test_table_without_leading_pipes(self):
        self.assertUnchanged(f'a | b\n--- | ---\n{LONG} {LONG} | x\n')

    def test_html_block(self):
        self.assertUnchanged(f'<div>\n{LONG} {LONG}\nx\n</div>\n')

    def test_html_comment_spanning_blank_lines(self):
        self.assertUnchanged(f'<!-- {LONG}\n\n{LONG} {LONG}\n-->\n')

    def test_link_reference_definition(self):
        self.assertUnchanged(f'[ref]: https://example.com/{"x" * 80}\n')

    def test_thematic_break(self):
        self.assertUnchanged('one\n\n---\n\ntwo\n')

    def test_skill_index_listing(self):
        self.assertUnchanged(f'# Skill index for foo\n- a: {LONG} {LONG}\n'
                             '- b\n')

    def test_paragraph_after_skill_index_is_wrapped(self):
        result = rewrap(f'# Skill index for foo\n- a: {LONG} {LONG}\n\n'
                        f'after {LONG} {LONG}\n')
        self.assertIn(f'- a: {LONG} {LONG}\n', result)
        for line in result.split('\n\n')[1].splitlines():
            self.assertLessEqual(len(line), 79)


class TestPartialRewrap(RewrapTestCase):
    """Re-wrapping only the touched lines, as the pre-commit hook does."""

    def test_untouched_paragraphs_are_left_alone(self):
        self.assertRewrapsTo('aaa\nbbb\n\nccc\nddd\n',
                             'aaa\nbbb\n\nccc ddd\n', lines=[4])

    def test_untouched_lines_of_the_same_paragraph_stay_as_written(self):
        # The lines before the edit are full, and once the new breaks line up
        # with the original ones the rest keeps its (non-greedy) breaks.
        self.assertRewrapsTo(
            markdown('''
                First line that stays exactly as it was written, and that is long enough.
                Second line.
                Third line that was edited to be very much longer than the eighty column limit.
                Fourth line.
                Fifth_line_starts_with_a_word_too_long_to_join_the_line_before_it and
                stays.
                Sixth.
                '''),
            markdown('''
                First line that stays exactly as it was written, and that is long enough.
                Second line. Third line that was edited to be very much longer than the eighty
                column limit. Fourth line.
                Fifth_line_starts_with_a_word_too_long_to_join_the_line_before_it and
                stays.
                Sixth.
                '''),
            lines=[3])

    def test_cascade_stops_once_breaks_line_up(self):
        long_word = 'x' * 75
        self.assertRewrapsTo(
            'aaa bbb ccc\nddd ' + ' '.join(['eee'] * 20) + '\nshort.\n'
            f'{long_word} ok\nkept   as   written\n',
            'aaa bbb ccc ddd ' + ' '.join(['eee'] * 16) + '\n'
            + ' '.join(['eee'] * 4) + ' short.\n'
            f'{long_word} ok\nkept   as   written\n',
            lines=[2])

    def test_cascade_onto_later_lines(self):
        # The example from 2026-10-25 that stopped too early: lengthening the
        # second line pushed words down, and the cascade stopped after one
        # line, leaving "currentRoundId," orphaned on a line of its own.
        original = markdown('''
            - `teamLinks/{token}` — a coach's shareable team link (issue #49),
              `<app root>?team=<token>` (such as `https://scoretec.app/react?team=<token>`); the id is a link token minted like a player
              token. Fields: `clubId, ownerUid, active, settings, currentRoundId,
              createdAt, updatedAt` — the settings and round are the team's current
              version, rewritten by the coach page alongside the roster
              (`applySettingsToTeamLinks`). Anyone may `get` it; only the owner may
              write it.
            ''')
        expected = markdown('''
            - `teamLinks/{token}` — a coach's shareable team link (issue #49),
              `<app root>?team=<token>` (such as
              `https://scoretec.app/react?team=<token>`); the id is a link token minted
              like a player token. Fields: `clubId, ownerUid, active, settings,
              currentRoundId, createdAt, updatedAt` — the settings and round are the team's
              current version, rewritten by the coach page alongside the roster
              (`applySettingsToTeamLinks`). Anyone may `get` it; only the owner may
              write it.
            ''')
        result = rewrap(original, lines=[2])
        self.assertEqual(result, expected)
        self.assertNotIn('\n  currentRoundId,\n', result)

    def test_cascade_onto_earlier_lines(self):
        # Earlier lines that were wrapped shorter than needed take words from
        # the edited stretch.
        self.assertRewrapsTo(
            markdown('''
                Some paragraph whose first line is short.
                Second line that is
                also short and then a third line that was edited to be quite a bit longer than the limit allows.
                Fourth line unchanged here and it continues on for a while past.
                '''),
            markdown('''
                Some paragraph whose first line is short. Second line that is also short and
                then a third line that was edited to be quite a bit longer than the limit
                allows. Fourth line unchanged here and it continues on for a while past.
                '''),
            lines=[3])

    def test_hand_wrapped_paragraph_reflows_after_the_edit(self):
        # A paragraph wrapped narrower than 79 never lines up with the new
        # breaks, so the rest of it is reflowed.
        self.assertRewrapsTo(
            markdown('''
                This paragraph was wrapped by hand at about fifty
                columns, and someone added several extra words to this line here.
                The rest of it continues on in the same narrow
                style for a few more lines so that we can see
                whether the cascade reflows all of it or not.
                '''),
            markdown('''
                This paragraph was wrapped by hand at about fifty columns, and someone added
                several extra words to this line here. The rest of it continues on in the same
                narrow style for a few more lines so that we can see whether the cascade
                reflows all of it or not.
                '''),
            lines=[2])

    def test_shortened_line_pulls_words_up(self):
        self.assertRewrapsTo(
            markdown('''
                The quick brown fox jumps over the lazy dog, and then it keeps on running
                through.
                It reaches the river at the edge of the field and stops for a drink.
                '''),
            markdown('''
                The quick brown fox jumps over the lazy dog, and then it keeps on running
                through. It reaches the river at the edge of the field and stops for a drink.
                '''),
            lines=[2])

    def test_cascade_does_not_cross_hard_line_break(self):
        self.assertRewrapsTo(
            f'edited {LONG} {LONG}  \nshort\nlines\n',
            'edited ' + ' '.join(['word'] * 14) + '\n'
            + ' '.join(['word'] * 16) + '\n'
            'word word word word  \nshort\nlines\n',
            lines=[1])

    def test_touched_verbatim_block_is_unchanged(self):
        self.assertUnchanged(f'```\n{LONG} {LONG}\n```\n', lines=[2])

    def test_touched_line_inside_block_quote(self):
        self.assertRewrapsTo('> aaa\n> bbb\n\n> ccc\n> ddd\n',
                             '> aaa\n> bbb\n\n> ccc ddd\n', lines=[5])

    def test_untouched_whitespace_only_line_is_kept(self):
        self.assertUnchanged('one\n   \ntwo\n', lines=[3])

    def test_lines_count_from_top_of_file_including_front_matter(self):
        self.assertRewrapsTo('---\nname: x\n---\naaa\nbbb\n\nccc\nddd\n',
                             '---\nname: x\n---\naaa\nbbb\n\nccc ddd\n',
                             lines=[7])

    def test_touching_every_line_matches_full_rewrap(self):
        documents = [
            f'- top {LONG}\n  more\n- next\n\n> quote {LONG}\n',
            f'aaa\nbbb {LONG} {LONG}\nccc\n\n1. one\n2. two {LONG}\n',
            'short\nlines\nhere\n\n```\ncode\n```\n',
        ]
        for document in documents:
            every_line = range(1, document.count('\n') + 2)
            self.assertEqual(rewrap(document, every_line), rewrap(document))


class TestIdempotence(RewrapTestCase):
    def test_rewrapping_twice_changes_nothing(self):
        document = markdown(f'''
            # Title

            Intro {LONG} {LONG}

            - item {LONG}
              - nested {LONG}
            1. ordered {LONG}

            > quote {LONG} {LONG}

            [^1]: note {LONG}
            ''')
        once = rewrap(document)
        self.assertEqual(rewrap(once), once)

    def test_skill_files_in_this_repo_are_stable(self):
        # Every committed skill file has been through the hook, so a full
        # re-wrap of the already wrapped output must be a no-op.
        repo = SCRIPT.parent.parent
        files = subprocess.run(
            ['git', 'ls-files', 'claude/skills/*.md'], cwd=repo,
            capture_output=True, text=True, check=True).stdout.split()
        self.assertTrue(files)
        for path in files:
            with self.subTest(path=path):
                once = rewrap((repo / path).read_text(encoding='utf-8'))
                self.assertEqual(rewrap(once), once)


class TestCommandLine(unittest.TestCase):
    def run_script(self, *arguments, input=None, cwd=None):
        return subprocess.run([sys.executable, str(SCRIPT), *arguments],
                              input=input, capture_output=True, text=True,
                              cwd=cwd)

    def test_standard_input_filter(self):
        result = self.run_script('-', input='one\ntwo\n')
        self.assertEqual(result.stdout, 'one two\n')

    def test_rewrites_file_in_place(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / 'a.md'
            path.write_text('one\ntwo\n')
            result = self.run_script(str(path))
            self.assertEqual(result.returncode, 0)
            self.assertEqual(path.read_text(), 'one two\n')
            self.assertIn('Re-wrapped', result.stdout)

    def test_check_reports_without_writing(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / 'a.md'
            path.write_text('one\ntwo\n')
            result = self.run_script('--check', str(path))
            self.assertEqual(result.returncode, 1)
            self.assertEqual(path.read_text(), 'one\ntwo\n')
            path.write_text('one two\n')
            self.assertEqual(self.run_script('--check', str(path)).returncode,
                             0)

    def test_diff_prints_without_writing(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / 'a.md'
            path.write_text('one\ntwo\n')
            result = self.run_script('--diff', str(path))
            self.assertIn('+one two', result.stdout)
            self.assertEqual(path.read_text(), 'one\ntwo\n')

    def test_lines_option(self):
        result = self.run_script('--lines', '4-5', '-',
                                 input='aaa\nbbb\n\nccc\nddd\n')
        self.assertEqual(result.stdout, 'aaa\nbbb\n\nccc ddd\n')

    def test_lines_option_requires_one_file(self):
        result = self.run_script('--lines', '1', 'a.md', 'b.md')
        self.assertNotEqual(result.returncode, 0)

    def test_warns_about_lines_still_too_long(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / 'a.md'
            path.write_text('see https://example.com/' + 'x' * 80 + ' ok\n')
            result = self.run_script(str(path))
            self.assertIn('still longer than 79', result.stderr)

    def test_no_warning_for_verbatim_long_lines(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / 'a.md'
            path.write_text(f'# {LONG} {LONG}\n')
            result = self.run_script(str(path))
            self.assertEqual(result.stderr, '')


class TestPreCommitHook(unittest.TestCase):
    """Run the hook script directly in a scratch repository."""

    def setUp(self):
        self.folder = tempfile.TemporaryDirectory()
        self.repo = Path(self.folder.name)
        self.environment = dict(
            os.environ,
            PATH=f'{SCRIPT.parent}{os.pathsep}{os.environ["PATH"]}',
            GIT_CONFIG_GLOBAL=os.devnull, GIT_CONFIG_NOSYSTEM='1',
            GIT_AUTHOR_NAME='Test', GIT_AUTHOR_EMAIL='test@example.com',
            GIT_COMMITTER_NAME='Test', GIT_COMMITTER_EMAIL='test@example.com')
        self.git('init', '-q')
        (self.repo / 'skill').mkdir()
        self.write('skill/SKILL.md', '---\nname: x\n---\n\nIntro.\n')
        self.write('skill/reference.md', 'aaa\nbbb\n\nccc\nddd\n')
        self.write('notes.md', 'aaa\nbbb\n')
        self.git('add', '.')
        self.git('commit', '-q', '--no-verify', '-m', 'Start')

    def tearDown(self):
        self.folder.cleanup()

    def git(self, *arguments):
        return subprocess.run(['git', *arguments], cwd=self.repo,
                              env=self.environment, capture_output=True,
                              text=True, check=True).stdout

    def write(self, path, text):
        (self.repo / path).write_text(text)

    def run_hook(self):
        return subprocess.run(['bash', str(HOOK)], cwd=self.repo,
                              env=self.environment, capture_output=True,
                              text=True)

    def staged(self, path):
        return self.git('show', f':{path}')

    def test_rewraps_only_touched_paragraph_and_stages_it(self):
        self.write('skill/reference.md', 'aaa\nbbb\n\nccc\nddd eee\n')
        self.git('add', 'skill/reference.md')
        result = self.run_hook()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.staged('skill/reference.md'),
                         'aaa\nbbb\n\nccc ddd eee\n')
        self.assertEqual((self.repo / 'skill/reference.md').read_text(),
                         'aaa\nbbb\n\nccc ddd eee\n')
        self.assertIn('Re-wrapped skill/reference.md', result.stderr)

    def test_cascades_through_paragraph(self):
        self.write('skill/reference.md', markdown('''
            - `teamLinks/{token}` — a coach's shareable team link (issue #49),
              `<app root>?team=<token>` (such as `https://scoretec.app/react?team=<token>`); the id is a link token minted like a player
              token. Fields: `clubId, ownerUid, active, settings, currentRoundId,
              createdAt, updatedAt` — the settings and round are the team's current
              version.
            '''))
        self.git('add', '.')
        self.git('commit', '-q', '--no-verify', '-m', 'Add paragraph')
        text = (self.repo / 'skill/reference.md').read_text()
        self.write('skill/reference.md',
                   text.replace('a player\n  token.', 'a player token\n  .'))
        self.git('add', 'skill/reference.md')
        result = self.run_hook()
        self.assertEqual(result.returncode, 0, result.stderr)
        for line in self.staged('skill/reference.md').splitlines():
            self.assertNotEqual(line.strip(), 'currentRoundId,')

    def test_pure_deletion_joins_the_lines_that_meet(self):
        self.write('skill/reference.md', 'aaa\nbbb\n\nccc\nddd\n')
        self.write('skill/reference.md', 'aaa\nbbb\nccc\nddd\n')
        self.git('add', 'skill/reference.md')
        self.assertEqual(self.run_hook().returncode, 0)
        self.assertEqual(self.staged('skill/reference.md'),
                         'aaa bbb ccc ddd\n')

    def test_ignores_markdown_outside_skills(self):
        self.write('notes.md', 'aaa\nbbb\nccc\n')
        self.git('add', 'notes.md')
        self.assertEqual(self.run_hook().returncode, 0)
        self.assertEqual(self.staged('notes.md'), 'aaa\nbbb\nccc\n')

    def test_file_in_skill_subfolder_counts(self):
        (self.repo / 'skill/deeper').mkdir()
        self.write('skill/deeper/more.md', 'aaa\nbbb\n')
        self.git('add', '.')
        self.assertEqual(self.run_hook().returncode, 0)
        self.assertEqual(self.staged('skill/deeper/more.md'), 'aaa bbb\n')

    def test_blocks_when_file_also_has_unstaged_changes(self):
        self.write('skill/reference.md', 'aaa\nbbb\n\nccc\nddd eee\n')
        self.git('add', 'skill/reference.md')
        self.write('skill/reference.md', 'aaa\nbbb\n\nccc\nddd eee\n\nfff\n')
        result = self.run_hook()
        self.assertEqual(result.returncode, 1)
        self.assertIn('unstaged changes', result.stderr)
        self.assertEqual(self.staged('skill/reference.md'),
                         'aaa\nbbb\n\nccc\nddd eee\n')

    def test_unstaged_changes_do_not_block_if_no_rewrap_needed(self):
        self.write('skill/reference.md', 'aaa\nbbb\n\nccc\nddd\n\neee\n')
        self.git('add', 'skill/reference.md')
        self.write('skill/reference.md', 'aaa\nbbb\n\nccc\nddd\n\neee\nfff\n')
        self.assertEqual(self.run_hook().returncode, 0)

    def test_skips_quietly_when_script_is_not_on_path(self):
        self.environment['PATH'] = '/usr/bin:/bin'
        self.write('skill/reference.md', 'aaa\nbbb\n\nccc\nddd eee\n')
        self.git('add', 'skill/reference.md')
        result = self.run_hook()
        self.assertEqual(result.returncode, 0)
        self.assertIn('not on PATH', result.stderr)


if __name__ == '__main__':
    unittest.main()
