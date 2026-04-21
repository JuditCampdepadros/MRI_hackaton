#!/bin/bash

# Make sure that the fmriprep-docker wrapper is installed in your venv
# and that the venv is activated

# ⚠️ run this script in the background using the following ⚠️
# nohup ./run_fmriprep.sh >> fmriprep.log 2>&1 &


# ── Specify desired paths ───────────────────────────────────────
bids_root="/data03/MRI_hackaton_JCB/Data_collection/bids"
deriv_root="/data03/MRI_hackaton_JCB/Data_collection/fmriprep"
work_dir="/data00/EmoReg_running_analyses/MRI_hackaton/fmriprep_work_MASSIVE_DELETE_ASAP"


# ── Do not touch anything below! ────────────────────────────────

if [ -t 1 ]; then
    echo ""
    echo "  ⚠️  Do not run this script directly."
    echo "  fMRIprep is a long-running job. Launch it in the background:"
    echo ""
    echo "      nohup ./run_fmriprep.sh >> fmriprep.log 2>&1 &"
    echo ""
    echo "  Then monitor with:  tail -f fmriprep.log"
    echo ""
    exit 1
fi


# Create the work_dir so that docker can work in it and the user
# can remove it once fmriprep has finished
[ ! -d ${work_dir} ] && mkdir -p ${work_dir}


# ── FreeSurfer license ─────────────────────────────────────────────────────
# Some users may not have FREESURFER_HOME set in their environment
FREESURFER_HOME="/usr/local/freesurfer"


# ── Parallelism ──────────────────────────────────────────────────────
# --nprocs:       workflow-level parallelism (independent nodes at once)
# --omp-nthreads: thread-level parallelism per process (ANTs, ITK)
# Total threads ≈ nprocs × omp-nthreads
nprocs=5
omp_nthreads=3
# On Storm there are 2 threads per core (36), so 72 threads total. 

# ── MNI target resolution 1/2/3 mm ───────────────────────────────────
MNI_res=3
# fMRIprep defaults to 2, but since I acquire in 3 mm, so there's no point in upsampling to 2 mm.

echo "=== fMRIprep started: $(date) ==="

# ── Run fMRIprep ───────────────────────────────────────────────────────────
fmriprep-docker \
    ${bids_root} \
    ${deriv_root} \
    participant \
    -u $(id -u):$(id -g) \
    --no-tty \
    --fs-no-reconall \
    --fs-license-file ${FREESURFER_HOME}/license.txt \
    --output-spaces MNI152NLin2009cAsym:res-${MNI_res} \
    --nprocs ${nprocs} \
    --omp-nthreads ${omp_nthreads} \
    --write-graph \
    --notrack \
    -w ${work_dir}

    

echo "=== fMRIprep finished: $(date) ==="

# u: run as current user, not root
# no-tty: disable interactive prompts 
# fs-no-reconall: skip FreeSurfer's recon-all (surface-based processing), goes faster
# output-spaces: specify MNI template and resolution for output
# fd/dvars-spike-threshold: thresholds for flagging motion outliers, it creates a motion outlier predictor 
# with all vols that exceed these thresholds, which can be used in later analyses to control for motion, default fd = 0.5, default dvars = 1.5
# write-graph: saves a graph of the workflow, useful for debugging
# notrack: disable anonymous usage tracking (optional, but some prefer it for privacy)
