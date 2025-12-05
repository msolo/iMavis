# Mavis AAC Help

Mavis AAC has a few features designed to make composing messages easier. This application was designed and built for a specific person who was a very competent typist, but who also possessed a distinct antipathy for computing technology.

The default settings and capabilities were strongly influenced by her needs and abilities as well as my best guesses on how to make living with this technology easier for her. There are many possible ways to modify and improve the software for specific needs.

# Text To Speech Intro

You can be lazy. Text to speech does not care about capitalization and usually doesn't care much about homophones either - their, they're and there are all pronounced about the same.

Sometimes there are subtle differences with some punctuation, like hyphens and commas. Unfortunately, right now most of the voices don't recognize the difference between `"Hello."`, `"Hello?"` and `"Hello!"` -- that's a current limitation of the Apple Speech synthesizer.

If there is a persistent problem, there are ways to tweak pronunciation inside the voice synthesizer. See the section on **Pronunciations**.

# Keyboard Navigation

You shouldn’t need to use menus with Mavis most of the time. Hunting through menus takes your fingers off the home row and ends up slowing you down.

Whatever you type in the composition text will be spoken when you press **Return**.

The last 10 phrases are remembered and you can quickly access them using the **Command** key ⌘ and up ↑ and down ↓ arrow keys.

Swiping items in the history list will allow you to delete a history item.

All the standard Mac keyboard navigation tricks work.

⌘← and ⌘→ (**Command** with the left or right arrow keys) will let you skip to the beginning or end of the composition.

⌥← and ⌥→ (**Option** with the left or right arrow keys) will let you skip backward and forward word by word.

⌥ Delete (Option with Delete) will delete a "word" backwards.

# Message History

If you need to quickly repeat the last message, **Command** key and Return **⌘-Return** will respeak the last message.

Alternatively, **Command** key and up arrow **⌘↑** will recall the last message in the history. **Return** will speak it aloud.

# Tab Completion

When you press the **Tab** key, Mavis AAC will suggest matching options from the list of preconfigured phrases and available soundbites based on the text already typed. Even small fragments of words can be used and they need not be in order. Matches will be ordered and the best match will be the last in the list, automatically selected.

For instance:
`blinds up`

Might result in the following suggestions:
 * It was nice catching up
 * Ask me Yes-No questions. It will speed things up.
 * **Could you raise the blinds up please?**

All of those match some fragment, but the last one matches "best" and would be selected automatically.

When the completion menu is showing, you can navigate the completion choices with the up **↑** and down **↓** arrow keys, or press the **Tab** and **Shift-Tab**.

The first press of the **Return** key will accept the current highlighted completion, and a second press of **Return** will speak the text aloud.

The **Escape** key (**esc** on the top left of your keyboard), cancels the completion menu and selects nothing.

> NOTE: There is no "best" way to do completions. This mechanism proved simple, fast, predictable and moderately effective. However, there are many ways to potentially alter the behavior.


# Phone and FaceTime

If you are on a call, Mavis is ready to help and you can speak with both your voice and the synthesizer.


# Speak Sentences Automatically

Mavis can (and does by default) automatically speak each sentence while you type. Technically, it speaks every time the space bar is pressed and the previous sentence ends with a period, exclamation point or question mark.

There is a preference for this in the **Chat** menu - **Speak Sentences Automatically**.

# Fixing Pronunciations

Under the **Settings** menu select **Edit Pronunciations...**.

Each line of this file corrects the pronunciation of a word.

For example, this line below tells the voice synthesizer that "Ez" - should be pronounced like "Ezz" - short for Ezra - instead of like E-Z as in "easy."

```
Ez|Ezz
```

This can't solve homographs (***read** 'em and weep* versus *I **read** that yesterday*), but if that's a problem, let me know. It's not unsolvable, just harder.

There is no requirement that pronunciation corrections have much to with the orthography. For instance, you can also do:

```
pepsi|coke
```

# Soundbites

Soundbites are voice bank recordings that you can play them back exactly as recorded. The catch is that what you type into Mavis must exactly match the phrase.

If you don't remember the exact phrase, type "z" and hit the **Tab** key - that will bring up all known phrases. You can scroll through them or type a few characters to show a limited set of matching results.

You can disable **Soundbites** in the **Chat** menu.

> NOTE: Soundbites do not play over Facetime or phone calls.

# Noisy Typing

Noisy Typing plays an audible click sound when you type into Mavis. This plays over the speakers to let people know that you are typing "conversationally", not beavering away on some other distraction on your device.

You can disable **Noisy Typing** in the **Chat** menu.

> NOTE: Noisy typing sounds do not play over Facetime or phone calls.

# Ring Bell

The Ring Bell button (or **Command-R** or **⌘R**) plays a ringing bell sound to get someone's attention without removing what you've already typed into Mavis.

The Double Bell button (or **Command-Shift-R** or **⌘⇧R**) is a litte louder and more aggressive.

The bell sounds were selected to be pleasant, but still capable of getting attention

The volume of the ring can be adjusted in the **Settings**.

# Settings

Adjusting the voice and volumes for various features is possible via the **Settings** panel.

## Voice Controls

Choose your voice and set it's basic speaking properties.

## Sound Effects

Adjust the volume of various sound effect.

## Input

Adjust how keyboard input is handled.

Minimum Return Key Delay is the to help prevent accidental double presses of the return key.

## Display

You can adjust the size of the font in the compose box to make it easier for you or others to read.

You can also adjust how long the display will stay awake when using the app to speak.

## Configuration

**Edit Pronunciations** and **Edit Phrases** should be self-explanatory.

**Import File** allows you to import several different special files that you have saved on your device.

### soundbites.zip

This zip archive can contain any number of sound files that are in the `.wav` or `.m4a` formats. The importer uses the name of the each file in the zip archive as the exact text to use when matching a soundbite.

For instance `Hello.wav` and `Hello!.wav` could be distinct entries. Typing "hello" would only match the first. "hello!" would only match the second.

### Removing Soundbites

If you find yourself wanting to remove a particular soundbite, you can use the **File** app to go into  `On My iPad` > `Mavis AAC` > `Soundbites` and delete the file from your device.

## Export

This lets you send any logged chats via Apple's sharing mechanisms to do some analysis. This mechanism was used to help train early versions of the text correction engine and collect data about patterns of typos or other systematic typing errors.

For this to be useful, you have to enable chat logging, which is obviously disabled by default to preserve privacy.

