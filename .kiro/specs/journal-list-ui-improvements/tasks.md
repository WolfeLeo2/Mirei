# Implementation Plan

- [x] 1. Set up project structure and core components

  - Create new folder structure for the redesigned journal list components
  - Set up shader asset directory and configuration
  - Create base data structures for folder management
  - _Requirements: 1.1, 1.2_

- [ ] 2. Implement adaptive folder layout system

  - [x] 2.1 Create AdaptiveFolderLayout widget

    - Build widget that switches between single folder and grid layouts
    - Implement logic to determine layout based on folder count
    - Create responsive layout calculations
    - _Requirements: 1.1, 7.1, 7.2_

  - [x] 2.2 Implement FolderGridView component

    - Create 3-column responsive grid layout
    - Handle mobile 2-column adaptation
    - Implement proper spacing and padding
    - _Requirements: 1.1, 4.1, 4.2_

  - [x] 2.3 Implement SingleFolderView component
    - Create centered large folder display
    - Implement 1.5x scaling for single folder mode
    - Ensure proper positioning and spacing
    - _Requirements: 7.1, 7.2, 7.3_

- [ ] 3. Create MonthFolderCard with CustomPainter

  - [x] 3.1 Build FolderPainter CustomPainter class

    - Implement folder shape drawing with rounded corners
    - Add shadow and depth effects
    - Create "folder lip" effect for realistic appearance
    - _Requirements: 2.1, 2.4_

  - [x] 3.2 Implement preview image integration

    - Add logic to extract first image from latest journal entry
    - Position preview image to appear "inside" folder
    - Handle cases with no images (placeholder/text preview)
    - _Requirements: 2.3, 2.5, 3.1_

  - [x] 3.3 Add folder labels and entry count
    - Implement month/year display with proper typography
    - Add entry count badge
    - Support both regular and large size modes
    - _Requirements: 2.2, 7.3_

- [ ] 4. Implement data grouping and sorting

  - [x] 4.1 Create journal grouping by month/year

    - Group existing journal entries by month and year
    - Implement chronological sorting (newest first)
    - Handle edge cases like empty months
    - _Requirements: 1.2, 1.3_

  - [x] 4.2 Add preview image extraction logic
    - Extract first image path from most recent entry in each month
    - Implement fallback logic for months without images
    - Cache preview images for performance
    - _Requirements: 2.3, 3.1_

- [ ] 5. Set up shader system foundation

  - [ ] 5.1 Create shader asset files

    - Create `shaders/custom_blur.frag` for blur effects
    - Create `shaders/morph_transition.frag` for morphing transitions
    - Add shader assets to pubspec.yaml configuration
    - _Requirements: 5.2, 5.3_

  - [ ] 5.2 Implement ShaderManager class
    - Create shader loading and initialization system
    - Implement uniform parameter management
    - Add error handling for shader compilation
    - _Requirements: 5.2, 5.3_

- [ ] 6. Build expansion animation system

  - [x] 6.1 Create ExpandedEntriesOverlay widget

    - Build full-screen overlay for expanded entries
    - Implement scattered position calculation algorithm
    - Create entry card layout for scattered display
    - _Requirements: 5.1, 6.1, 6.2_

  - [x] 6.2 Implement basic expansion/collapse animations

    - Add AnimationController setup for folder expansion
    - Create staggered entry emergence animations
    - Implement collapse animation (reverse of expansion)
    - _Requirements: 5.1, 5.4, 5.5_

  - [x] 6.3 Add tap handling and state management
    - Implement folder tap detection and state changes
    - Add outside tap detection for closing expanded folders
    - Manage animation states and prevent conflicts
    - _Requirements: 5.1, 5.4_

- [ ] 7. Integrate custom blur shader effects

  - [ ] 7.1 Implement custom blur background

    - Replace BackdropFilter with custom blur shader
    - Add radial blur emanating from folder position
    - Implement dynamic blur intensity based on animation progress
    - _Requirements: 5.2, 5.3_

  - [ ] 7.2 Add shader-based visual enhancements
    - Integrate blur shader with expansion animation
    - Add shader uniform updates during animation
    - Optimize shader performance for mobile devices
    - _Requirements: 5.2, 5.3_

- [ ] 8. Implement morphing transition shader

  - [ ] 8.1 Create morphing shader integration

    - Implement folder-to-entries morphing effect
    - Add smooth transition between folder and scattered states
    - Integrate morphing with expansion animation phases
    - _Requirements: 5.1, 5.3_

  - [ ] 8.2 Add particle effects during transition
    - Enhance morphing with particle-like effects
    - Implement visual continuity during transformation
    - Fine-tune morphing timing and easing
    - _Requirements: 5.1, 5.3_

- [ ] 9. Implement journal entry interaction

  - [x] 9.1 Create ScatteredEntryCard component

    - Build individual journal entry cards for scattered display
    - Include date, title, content preview, and mood display
    - Add proper touch targets and visual feedback
    - _Requirements: 6.2, 6.3_

  - [x] 9.2 Add entry actions and navigation
    - Implement tap handling for viewing journal entries
    - Add context menu or action buttons for edit/delete
    - Integrate with existing JournalViewScreen navigation
    - _Requirements: 6.3, 6.4_

- [ ] 10. Replace existing journal list implementation

  - [x] 10.1 Update JournalListScreen to use new components

    - Replace existing folder structure with new grid layout
    - Integrate AdaptiveFolderLayout as main content
    - Maintain existing AppBar and FloatingActionButton
    - _Requirements: 1.1, 7.4_

  - [x] 10.2 Handle state management and data flow
    - Update data loading to work with new grouping system
    - Ensure proper state updates when journals are added/deleted
    - Maintain existing database integration
    - _Requirements: 1.1, 4.3_

- [ ] 11. Add performance optimizations

  - [x] 11.1 Optimize animation performance

    - Implement animation frame rate monitoring
    - Add memory management for animation controllers
    - Optimize shader rendering for smooth 60fps
    - _Requirements: 4.4, 5.5_

  - [x] 11.2 Add image caching and loading optimizations
    - Implement preview image caching system
    - Add lazy loading for folder preview images
    - Optimize image memory usage for large collections
    - _Requirements: 2.3, 4.4_

- [ ] 12. Testing and polish

  - [ ] 12.1 Add comprehensive testing

    - Create unit tests for data grouping and sorting logic
    - Add widget tests for folder rendering and animations
    - Implement integration tests for full expansion workflow
    - _Requirements: All requirements_

  - [ ] 12.2 Final polish and bug fixes
    - Fine-tune animation timing and easing curves
    - Adjust visual styling and spacing
    - Fix any edge cases or performance issues
    - _Requirements: All requirements_
