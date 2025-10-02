#!/usr/bin/env fish

# Simple Foresight: Apply Comprehensive Improvements
# A joyful script to safely apply changes from Claude's artifacts

# Resolve repo root robustly so this can run from any CWD
set -l SCRIPT_DIR (realpath (dirname (status --current-filename)))

# Try git first from current directory
set -l REPO_ROOT ""
if type -q git
    set -l git_root (git rev-parse --show-toplevel 2>/dev/null)
    if test -n "$git_root"
        set REPO_ROOT (realpath "$git_root")
    end
end

# Fallback: git from script directory
if test -z "$REPO_ROOT"; and type -q git
    pushd $SCRIPT_DIR >/dev/null
    set -l git_root2 (git rev-parse --show-toplevel 2>/dev/null)
    popd >/dev/null
    if test -n "$git_root2"
        set REPO_ROOT (realpath "$git_root2")
    end
end

# Final fallback: parent of script directory
if test -z "$REPO_ROOT"
    set REPO_ROOT (realpath "$SCRIPT_DIR/..")
end

# Ensure we execute from the repo root for consistent relative paths
if test -d "$REPO_ROOT"
    cd "$REPO_ROOT"
end

# Colors for output
set -l RED \e\[31m
set -l GREEN \e\[32m
set -l YELLOW \e\[33m
set -l BLUE \e\[34m
set -l RESET \e\[0m

function print_header
    echo
    echo "$BLUE════════════════════════════════════════════════════════════════$RESET"
    echo "$BLUE  $argv[1]$RESET"
    echo "$BLUE════════════════════════════════════════════════════════════════$RESET"
    echo
end

function print_success
    echo "$GREEN✓ $argv[1]$RESET"
end

function print_error
    echo "$RED✗ $argv[1]$RESET"
end

function print_warning
    echo "$YELLOW⚠ $argv[1]$RESET"
end

function print_info
    echo "$BLUE→ $argv[1]$RESET"
end

function confirm
    echo -n "$YELLOW? $argv[1] [y/N] $RESET"
    read -l response
    test "$response" = "y" -o "$response" = "Y"
end

# Check if we resolved the repo root correctly
if not test -f "$REPO_ROOT/simple/app.rb"
    print_error "Cannot locate repo root (checked $REPO_ROOT)."
    print_info "Expected to find simple/app.rb under the repository root."
    print_info "This script should live at simple/apply_improvement.fish and auto-detect the root."
    exit 1
end

print_header "Simple Foresight: Comprehensive Improvements"

echo "This script will:"
echo "  1. Create a new git branch"
echo "  2. Back up existing files"
echo "  3. Create new files from Claude's artifacts"
echo "  4. Show you diffs for review"
echo "  5. Run tests"
echo "  6. Commit changes"
echo

if not confirm "Ready to proceed?"
    print_info "Aborted by user"
    exit 0
end

# Check for uncommitted changes
print_header "Checking Git Status"
if not git diff-index --quiet HEAD --
    print_warning "You have uncommitted changes!"
    echo
    git status --short
    echo
    if not confirm "Continue anyway?"
        print_info "Aborted by user"
        exit 0
    end
end

# Create branch
print_header "Creating Feature Branch"
set -l BRANCH_NAME "feature/comprehensive-improvements"
if git rev-parse --verify $BRANCH_NAME >/dev/null 2>&1
    print_warning "Branch $BRANCH_NAME already exists!"
    if not confirm "Switch to it and continue?"
        print_info "Aborted by user"
        exit 0
    end
    git checkout $BRANCH_NAME
else
    git checkout -b $BRANCH_NAME
    print_success "Created and switched to branch: $BRANCH_NAME"
end

# Create backup directory
print_header "Creating Backups"
set -l BACKUP_DIR "backups/"(date +%Y%m%d_%H%M%S)
mkdir -p $BACKUP_DIR
print_info "Backing up to: $BACKUP_DIR"

# Backup existing files that will be modified
set -l files_to_backup \
    "simple/app.rb" \
    "simple/Gemfile" \
    "simple/views/index.slim" \
    "simple/public/js/chart_controller.js" \
    "simple/public/js/profile_controller.js" \
    "simple/public/js/application.js"

for file in $files_to_backup
    if test -f $file
        cp $file $BACKUP_DIR/(basename $file).bak
        print_success "Backed up: $file"
    end
end

# Create directories if they don't exist
print_header "Creating Directories"
mkdir -p spec
mkdir -p simple/public/js
print_success "Directories ready"

print_header "MANUAL STEP REQUIRED"
echo
print_warning "Claude cannot directly write files to your system."
echo
echo "Please open another terminal and copy the artifacts:"
echo
echo "$BLUE  1. Open the conversation with Claude in your browser$RESET"
echo "$BLUE  2. For each artifact below, copy its content to the specified file$RESET"
echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo

# List all files that need to be created/updated
echo "$GREEN NEW FILES:$RESET"
echo "  spec/simulator_spec.rb"
echo "    ↳ Artifact: 'spec/simulator_spec.rb'"
echo
echo "  VISION.md"
echo "    ↳ Artifact: 'Simple Foresight: Living Vision & Planning'"
echo
echo "  INCOME_SOURCES.md"
echo "    ↳ Artifact: 'Income Sources: Comprehensive Inventory & Implementation Plan'"
echo
echo "  simple/public/js/simulation_controller.js"
echo "    ↳ Artifact: 'public/js/simulation_controller.js'"
echo

echo "$YELLOW UPDATED FILES:$RESET"
echo "  simple/app.rb"
echo "    ↳ Artifact: 'app.rb (Updated with comprehensive handling)'"
echo
echo "  simple/Gemfile"
echo "    ↳ Artifact: 'Gemfile (with test dependencies)'"
echo
echo "  simple/views/index.slim"
echo "    ↳ Artifact: 'views/index.slim (Comprehensive Editors)'"
echo
echo "  simple/public/js/chart_controller.js"
echo "    ↳ Artifact: 'public/js/chart_controller.js (Chart.js version)'"
echo
echo "  simple/public/js/profile_controller.js"
echo "    ↳ Artifact: 'public/js/profile_controller.js (Updated)'"
echo
echo "  simple/public/js/application.js"
echo "    ↳ Artifact: 'public/js/application.js (Updated)'"
echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo

if not confirm "Have you copied all the files?"
    print_info "Come back when files are ready!"
    print_info "Backups are in: $BACKUP_DIR"
    exit 0
end

# Verify critical files exist
print_header "Verifying Files"
set -l critical_files \
    "spec/simulator_spec.rb" \
    "simple/public/js/simulation_controller.js" \
    "VISION.md" \
    "INCOME_SOURCES.md"

set -l missing_files 0
for file in $critical_files
    if test -f $file
        print_success "Found: $file"
    else
        print_error "Missing: $file"
        set missing_files (math $missing_files + 1)
    end
end

if test $missing_files -gt 0
    print_error "$missing_files file(s) missing!"
    if not confirm "Continue anyway?"
        exit 1
    end
end

# Install dependencies
print_header "Installing Dependencies"
if test -f simple/Gemfile
    cd simple
    bundle install
    cd ..
    print_success "Dependencies installed"
else
    print_error "simple/Gemfile not found!"
end

# Run tests
print_header "Running Tests"
if test -f spec/simulator_spec.rb
    ruby spec/simulator_spec.rb
    if test $status -eq 0
        print_success "All tests passed!"
    else
        print_error "Tests failed!"
        if not confirm "Continue with commit anyway?"
            print_info "Fix tests and run: git add . && git commit"
            exit 1
        end
    end
else
    print_warning "Test file not found, skipping tests"
end

# Show git status
print_header "Git Status"
git status --short

# Show diffs for review
print_header "Review Changes"
if confirm "Show detailed diffs?"
    git diff --cached
    git diff
end

# Stage changes
print_header "Staging Changes"
git add .
print_success "All changes staged"

# Commit
print_header "Committing Changes"
set -l commit_message "Comprehensive improvements: tests, editors, Chart.js, vision docs

- Add comprehensive test suite with Minitest
- Replace hand-coded SVG with Chart.js for maintainability
- Add separate Profile and Simulation editors for clear mental model
- Fix profile round-trip to include all parameters
- Remove localStorage in favor of honest ephemerality
- Add tax calculation limitation notices in UI
- Create living vision document with roadmap
- Create comprehensive income sources inventory and implementation plan
- Add detailed code comments explaining simplifications
- Update all controllers to handle complete profile structure

Follows 'Ode to Joy' principles: joyful, readable, well-tested, honest about limitations."

git commit -m "$commit_message"

if test $status -eq 0
    print_success "Changes committed!"
else
    print_error "Commit failed!"
    exit 1
end

# Summary
print_header "Summary"
echo "Branch:  $BRANCH_NAME"
echo "Backups: $BACKUP_DIR"
echo "Commit:  "(git rev-parse --short HEAD)
echo

print_success "Improvements successfully applied!"
echo
echo "Next steps:"
echo "  $BLUE→$RESET Review the commit: git show"
echo "  $BLUE→$RESET Test the application: cd simple && bundle exec rackup"
echo "  $BLUE→$RESET Push to remote: git push origin $BRANCH_NAME"
echo "  $BLUE→$RESET Merge to main when ready: git checkout main && git merge $BRANCH_NAME"
echo

print_header "🎉 Joy Achieved! 🎉"