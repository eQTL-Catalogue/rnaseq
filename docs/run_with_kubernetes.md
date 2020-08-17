# Executing pipeline with Kubernetes

## Configure Kubernetes cluster 

Take your kube.yml and add to the environment

```
export KUBECONFIG=<dir>/kube.yml
```

Create a persistent volume claim. Make a file called pvc.yaml with content like:

```
---
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: nextflow
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 45Gi
  storageClassName: nfs-client
```

and apply like:

```
kubectl create -f pvc.yaml 
```

Add a service account for Nextflow to use:

```
kubectl create sa nextflow-sa
```

Then give this account the appropriate permissions. Create the rbac.yaml config file like:

```
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  namespace: default
  name: nextflow-role 
rules:
- apiGroups: [""]
  resources: ["pods", "pods/log", "pods/status"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete" ]
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: nextflow-role-binding
subjects:
- kind: ServiceAccount
  name: nextflow-sa
  namespace: default
roleRef:
  kind: Role
  name: nextflow-role
  apiGroup: rbac.authorization.k8s.io
```

... then apply like:

```
kubectl create -f rbac.yaml 
```

Then create a nexflow.config to tell Nextflow about the cluster:

```
process.scratch = true
k8s {
  storageClaimName = 'nextflow'
  serviceAccount = 'nextflow-sa'
}
```

## Copy workflow inputs to the k8s cluster

First start a login pod so you have somewhere to copy to:

```
nextflow kuberun login
```

... then note the name of the pod and run the copy:

```
kubectl cp inputs <pod>:/workspace/<user>/inputs
```

## Run workflow

Then you can run the workflow:

```
READ_PATHS_FILE="inputs/readPathsFile_macrophages_PE.tsv"
HISAT_INDEX="inputs/reference/hisat2_index_v96/Homo_sapiens.GRCh38.dna.primary_assembly"
GTF="inputs/reference/gencode.v30.annotation.no_chr.gtf"
FASTA="inputs/reference/Homo_sapiens.GRCh38.dna.primary_assembly.fa.gz"
TX_FASTA="inputs/reference/gencode.v30.transcripts.fa.gz"
WORKFLOW="ebi-gene-expression-group/rnaseq-eqtl"

nextflow kuberun $WORKFLOW \
 -c nextflow.config \
 -latest \
 --readPathsFile $READ_PATHS_FILE \
 --reverse_stranded \
 --hisat2_index $HISAT_INDEX \
 --aligner 'hisat2' \
 --skip_qc \
 --skip_multiqc \
 --skip_stringtie \
 --saveReference \
 --run_tx_exp_quant \
 --run_splicing_exp_quant \
 --run_exon_quant \
 --saveTrimmed \
 --saveAlignedIntermediates\
 --gtf $GTF \
 --fasta $FASTA \
 --tx_fasta $TX_FASTA \
 -resume
```

## Copy results back from cluster

e.g.:

```
kubectl cp <pod>:/workspace/<user>/results $(pwd)/results
```

