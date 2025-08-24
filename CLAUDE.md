# BPtimer (Balanced Practice Timer)

BPtimer is a meditation timer app designed to help practitioners maintain a balanced meditation/mental development practice. It's implemented as a fully functional Progressive Web App with offline capabilities.

## GitHub Deployment Note
**IMPORTANT**: When the user asks to "push changes", this means:
1. Commit all changes to git
2. Push to GitHub repository (https://github.com/odcpw/bptimer)
3. Changes will automatically deploy to GitHub Pages (https://odcpw.github.io/bptimer/)

Only push changes when explicitly requested by the user. The phrase "push changes" always means updating BOTH the GitHub repository AND the live GitHub Pages site.

## Architecture Overview

### Files Structure
- `index.html` - Main HTML with semantic structure and ARIA labels
- `styles.css` - Complete styling with light/dark modes and responsive design
- `script.js` - Full app logic (2295 lines) with comprehensive LLM-friendly comments
- `sw.js` - Service worker for offline functionality
- `manifest.json` - PWA manifest for app installation
- `icon-*.png` - Placeholder icon files (need actual icons for production)

### Key Technical Decisions
- **No Framework**: Vanilla JavaScript for simplicity and performance
- **IndexedDB**: For unlimited session storage (vs localStorage limits)
- **Chart.js**: Loaded from CDN for statistics visualizations
- **Service Worker**: Network-first strategy with cache fallback
- **Unified SessionBuilder**: Single reusable component for both planning and recording sessions

## Implementation Details

### Practice Configuration
All practice categories are defined in the `PRACTICE_CONFIG` object. To add/modify practices:
```javascript
const PRACTICE_CONFIG = {
    categoryKey: {
        name: 'Display Name',
        practices: {
            'Practice Name': {
                info: 'Brief description of the practice'
            },
            'Practice with Subs': {  // Hierarchical practice
                'Subcategory': ['Option 1', 'Option 2']
            }
        }
    }
};
```

### State Management
- `timerState` - Timer-specific state within MeditationTimerApp constructor
- `appState` - App-wide settings and UI state within MeditationTimerApp constructor
- localStorage - Settings, favorites, recent sessions
- IndexedDB - Full session history

### Key Features Implementation

#### SessionBuilder Component
- **Unified component** for both session planning and post-session recording
- Handles practice selection, ordering, and drag-and-drop reordering
- Manages posture selection
- Single source of truth for session building UI/logic
- Configuration-based: same code serves both planning and recording contexts

#### Timer Flow
1. **Minimal timer view**: Just timer, duration controls, and buttons
2. **Optional session planner**: Collapsible section with SessionBuilder for planning
3. **Post-session recording**: Modal with SessionBuilder for recording actual practice

#### Hierarchical Menus
- Dynamic menu generation from `PRACTICE_CONFIG`
- Expandable categories with state tracking
- Support for nested subcategories

#### Statistics
- Calendar view with daily practice indicators
- Chart.js integration for visualizations
- Period selection (week/fortnight/month)
- Real-time calculation from IndexedDB

#### PWA Features
- Service worker caches all assets
- Manifest enables installation
- Works fully offline after first load

#### Visual Design
- Dark theme by default (no theme switching)
- Teal accent colors for interactive elements
- Responsive design for mobile and desktop

## Maintenance Guide

### Adding New Practices
1. Edit `PRACTICE_CONFIG` object in script.js
2. Follow existing structure for categories/subcategories
3. No other code changes needed - UI updates automatically

### Modifying Styles
- CSS variables in :root control colors
- Dark theme colors are the default (no light mode)
- Mobile breakpoint at 480px

### Debugging
- Check browser console for errors
- IndexedDB data visible in DevTools > Application > Storage
- Service worker status in DevTools > Application > Service Workers

### Performance Considerations
- Charts are created on-demand when viewing statistics
- IndexedDB queries are async to prevent blocking
- Recent sessions cached in localStorage for quick access

## Future Enhancements (Not Implemented)
- Real icon files (currently placeholders)
- Audio bells/notifications (intentionally omitted for simplicity)
- Cloud sync (intentionally omitted for privacy)
- Multi-language support
- Teacher/student sharing features

## Testing Checklist
- [ ] Timer starts, pauses, stops correctly
- [ ] Sessions save to IndexedDB
- [ ] Practice selection works in all categories
- [ ] Session planning adds/removes practices
- [ ] Favorites save and load
- [ ] Statistics display correctly
- [ ] PWA installs on mobile/desktop
- [ ] Works offline after installation
- [ ] Keyboard navigation functions
- [ ] Screen reader announces changes

## Browser Compatibility
Tested and working in:
- Chrome 90+
- Firefox 88+
- Safari 14+
- Edge 90+

Features that may not work in older browsers:
- Wake Lock API (keeps screen on)
- PWA installation
- Some modern CSS features

## Known Limitations
1. Icon files are placeholders - need actual PNG icons
2. Charts require internet on first load (CDN)
3. Wake Lock only works on HTTPS or localhost
4. No data sync between devices (by design)

## Code Style Notes
- Clear function names with comprehensive JSDoc comments
- Logical code organization by feature
- Event handlers defined separately
- Async/await for all IndexedDB operations
- No external dependencies except Chart.js
- Reusable components (SessionBuilder) to avoid code duplication
- Configuration-based design for flexibility
- LLM-friendly comments explaining purpose, functionality, and behavior
- JSDoc annotations for function parameters and return values