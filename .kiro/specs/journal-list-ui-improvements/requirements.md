# Requirements Document

## Introduction

This feature transforms the journal list screen from a vertical expandable folder structure to a modern horizontal grid layout. The new design will display month/year folders as cards arranged in a 3-column grid, similar to a file manager interface, where each folder represents a specific month (e.g., "August 2025") and contains all journal entries for that period.

## Requirements

### Requirement 1

**User Story:** As a user, I want my journal entries organized in a horizontal grid of month folders, so that I can quickly browse and access entries by time period in a visually appealing way.

#### Acceptance Criteria

1. WHEN I open the journal list screen THEN folders SHALL be displayed in a horizontal grid layout with 3 folders per row
2. WHEN I view the folder grid THEN each folder SHALL represent a specific month and year (e.g., "August 2025")
3. WHEN I view folders THEN they SHALL be sorted chronologically with the most recent months first
4. WHEN I tap on a folder THEN it SHALL navigate to show the journal entries for that specific month

### Requirement 2

**User Story:** As a user, I want each month folder to display as a clean, modern card that appears "full" with content, so that I can easily identify and differentiate between different time periods.

#### Acceptance Criteria

1. WHEN I view a month folder THEN it SHALL display as a card with clean white background and rounded corners
2. WHEN I view a folder card THEN it SHALL show the month and year prominently (e.g., "August 2025")
3. WHEN I view a folder card THEN it SHALL display the first image from the latest journal entry as a preview to make the folder appear "full"
4. WHEN I view a folder card THEN it SHALL have appropriate shadows and visual depth similar to the reference image
5. WHEN a month has no journal entries with images THEN the folder SHALL display an appropriate placeholder or text preview

### Requirement 3

**User Story:** As a user, I want the folder cards to show visual indicators of the content within, so that I can quickly understand what type of entries are in each month.

#### Acceptance Criteria

1. WHEN I view a folder card THEN it SHALL display a preview or indicator of the content type within
2. WHEN a month contains entries with images THEN the folder SHALL show a visual indicator for media content
3. WHEN a month contains entries with audio recordings THEN the folder SHALL show an appropriate audio indicator
4. WHEN a month contains entries with different moods THEN the folder SHALL reflect this with subtle color accents

### Requirement 4

**User Story:** As a user, I want the grid layout to be responsive and work well on different screen sizes, so that I can use the journal list effectively on various devices.

#### Acceptance Criteria

1. WHEN I view the journal list on different screen sizes THEN the grid SHALL adapt appropriately while maintaining 3 columns on standard screens
2. WHEN I view the journal list on smaller screens THEN the grid SHALL adjust to 2 columns if necessary
3. WHEN I interact with folder cards THEN they SHALL have appropriate touch targets and spacing
4. WHEN I scroll through the folder grid THEN the performance SHALL be smooth and responsive

### Requirement 7

**User Story:** As a user, I want a single month folder to be prominently displayed when it's the only folder available, so that I can easily access my journal entries with a more focused interface.

#### Acceptance Criteria

1. WHEN there is only one month folder available THEN it SHALL be displayed centered on the page
2. WHEN there is only one month folder THEN it SHALL be significantly larger than folders in a multi-folder grid
3. WHEN there is only one month folder THEN it SHALL maintain the same visual style and functionality as grid folders
4. WHEN additional months are added THEN the layout SHALL transition smoothly to the grid format

### Requirement 5

**User Story:** As a user, I want folders to expand with a dramatic "gushing out" animation and blur effect, so that I can view journal entries in an engaging and visually stunning way.

#### Acceptance Criteria

1. WHEN I tap on a month folder THEN the journal entries SHALL "gush out" or spill out from the folder with a dynamic animation
2. WHEN a folder expands THEN the background and other folders SHALL be blurred to create visual hierarchy and focus
3. WHEN entries gush out THEN they SHALL be positioned in a scattered, organic layout around the original folder position
4. WHEN I tap outside the expanded entries or on a close button THEN the entries SHALL animate back into the folder
5. WHEN a folder collapses THEN the blur effect SHALL be removed and all folders SHALL return to normal visibility

### Requirement 6

**User Story:** As a user, I want the expanded journal entries to display as individual cards in a scattered layout, so that I can easily browse and interact with my journal content.

#### Acceptance Criteria

1. WHEN I view expanded journal entries THEN they SHALL be displayed as individual cards scattered around the original folder position
2. WHEN I view journal entry cards THEN each SHALL show relevant information like date, title, content preview, and mood
3. WHEN I interact with journal entry cards THEN I SHALL be able to tap them to view, edit, or access additional actions
4. WHEN I view the scattered entries THEN the layout SHALL be visually appealing and easy to navigate
