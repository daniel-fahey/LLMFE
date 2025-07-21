# Paper Reproduction Workflow Guide

**Audience**: Future Claude instances helping to reproduce ML paper results  
**Context**: This guide documents the systematic approach for setting up and reproducing machine learning research papers

## Phase 1: Initial Codebase Analysis

### 1.1 Environment Discovery
- **Always check for Nix first**: Look for `flake.nix`, `shell.nix`, or `default.nix`
- **Python management**: Prefer `uv` over conda/pip when available
- **Dependencies**: Read `requirements.txt`, `pyproject.toml`, or `Pipfile`

### 1.2 Codebase Structure Analysis
Use these tools systematically:
```bash
# Get overview
LS /path/to/repo

# Find key files  
Glob "**/*.py"
Glob "**/main.py"
Glob "**/requirements.txt"
Glob "**/README.md"

# Understand entry points
Read main.py
Read setup.py  # if exists
```

### 1.3 Documentation Creation
**Always create CLAUDE.md** with:
- Environment setup (prioritize Nix + uv)
- Common commands for running experiments
- High-level architecture overview
- Key patterns and conventions
- Configuration parameters

## Phase 2: Paper Analysis

### 2.1 Paper Extraction and Reading
```bash
# If arxiv tarball provided
mkdir paper
tar -xzf arxiv-paper.tar.gz -C paper

# Focus on these sections:
- Abstract (claims and scope)
- Experimental Setup
- Implementation Details  
- Reproducibility Statement
- Appendix (detailed parameters)
```

### 2.2 Key Information to Extract
- **Datasets**: Names, sources, train/test splits, preprocessing
- **Model configurations**: Hyperparameters, architectures, training procedures
- **Evaluation metrics**: Primary metrics, reporting format (mean±std, etc.)
- **Computational requirements**: Hardware, runtime, API costs
- **Baseline comparisons**: Which methods, how configured

## Phase 3: Environment Setup

### 3.1 Nix + UV Workflow (Preferred)
```bash
# Enter development shell
nix develop

# Install Python dependencies  
uv sync
```

### 3.2 Secret Management
- **Use agenix-shell** for API keys and sensitive data
- **Never commit secrets** - ensure `.gitignore` includes `secrets/`
- **Environment variables** automatically loaded in shell

### 3.3 Dependency Verification
- Check if all required packages are available
- Verify CUDA setup for GPU-dependent code
- Test basic imports and model loading

## Phase 4: Reproduction Guide Creation

### 4.1 Structure the Guide
Create `doc/reproduce.md` with:

1. **Environment Setup**: Exact commands to get running
2. **Dataset Overview**: What's included, what might be missing  
3. **Core Configuration**: Key parameters from paper
4. **Running Experiments**: Command examples, batch scripts
5. **Expected Results**: Performance baselines, metrics format
6. **Troubleshooting**: Common issues and solutions

### 4.2 Essential Sections
- **Quick Start**: Single dataset example to verify setup
- **Batch Reproduction**: Commands for systematic evaluation
- **Computational Requirements**: Hardware, time, cost estimates
- **Output Interpretation**: How to read results and logs

## Phase 5: Verification Steps

### 5.1 Smoke Tests
- Run one small/fast dataset end-to-end
- Verify outputs match expected format
- Check that baselines can be compared fairly

### 5.2 Resource Planning  
- Estimate computational cost (GPU hours, API calls)
- Plan batch execution strategy
- Set up logging and monitoring

## Key Principles for Claude

### Always Do
- **Start with environment** - get the setup right first
- **Read the paper thoroughly** - especially implementation details
- **Create comprehensive docs** - future Claude will thank you
- **Test incrementally** - start small, scale up
- **Document everything** - assumptions, parameters, deviations

### Never Do
- **Skip the Reproducibility Statement** - it contains crucial details
- **Assume default parameters** - papers often use non-standard settings
- **Ignore computational constraints** - some experiments are expensive
- **Commit secrets** - use proper secret management

### Common Pitfalls
- **Missing datasets**: Papers often use more data than provided in repos
- **Version mismatches**: Dependency versions can significantly affect results
- **Hardware differences**: GPU memory, CUDA versions, etc.
- **API rate limits**: Plan for delays with commercial APIs
- **Evaluation differences**: Subtle differences in train/test splits or metrics

## Template Commands

### Environment Setup
```bash
nix develop                    # Enter Nix shell
uv sync                       # Install dependencies  
echo $OPENAI_API_KEY          # Verify secrets loaded
```

### Basic Reproduction
```bash
# Single dataset test
uv run python main.py --problem_name <dataset> --spec_path ./specs/specification_<dataset>.txt --log_path ./logs/<dataset>_test

# Batch processing template
for dataset in dataset1 dataset2 dataset3; do
  uv run python main.py --problem_name $dataset --spec_path ./specs/specification_$dataset.txt --log_path ./logs/${dataset}_reproduction
done
```

### Common Investigation Commands
```bash
# Check dataset availability
ls data/

# Verify model configurations
grep -r "temperature\|batch_size\|learning_rate" .

# Monitor resource usage
nvidia-smi              # GPU usage
htop                   # CPU/memory
```

This systematic approach ensures consistent, thorough reproduction attempts while building proper documentation for future work.