# Bulletproofs (WIP) {#chapter:bulletproofs}

## Vector Knowledge Proof {#sec:vectorzkproof}

Prove knowledge of all elements in vector set $\boldsymbol{V}$
containing $m$ vectors of size $N$ ($m \neq N$), committed to in
$(C_1, C_2,..., C_m)$ where
$C_i = v_{i,1}*H_1 + v_{i,2}*H_2 + ... + v_{i,N}*H_N$. The discrete
logarithms with respect to $G$ of generators in vector
$\boldsymbol{H} = \langle H_1,..., H_N \rangle$,
$\boldsymbol{\lambda} = \langle \lambda_1, ..., \lambda_N \rangle$, are
unknown (and e.g. the discrete log of $H_2$ with respect to $H_4$).
Verifiers know there are $m*N$ elements, but gain no information about
them.

#### Non-interactive proof {#non-interactive-proof .unnumbered}

1.  Generate a vector (size N+1) of random integers
    $\boldsymbol{\alpha} \in_R \mathbb{Z}_l$, and compute the inner
    product $C_{\alpha} = \boldsymbol{\alpha} \bullet \textbf{H}$.[^1]

2.  Calculate the *challenge*
    $c = \mathcal{H}(T_{vec},\boldsymbol{V},C_{\alpha})$.[^2]

3.  Define the *response vector* (size N+1) $\textbf{r}$, with an
    element $r_j$ for each generator $H_j$ (imagine vectors listed out
    in rows, and here we take the column sum with one $v_{i,j}$ from
    each vector $i$) (note each one is multiplied by $c$ raised to power
    $i$) $$r_j = \alpha_j - \sum^{m}_{i=1} c^i*v_{i,j}$$

4.  Publish the proof pair $(c, \boldsymbol{r})$.

#### Verification {#verification .unnumbered}

1.  Calculate the challenge:
    $c' = \mathcal{H}(...,\textbf{r} \bullet \textbf{H} + \sum^{m}_{i=1} (c')^i*C_i)$.

2.  If $c = c'$ then the prover must know $\boldsymbol{V}$ (except with
    negligible probability).

#### Why it works {#why-it-works .unnumbered}

$$\begin{aligned}
\textbf{r} \bullet \textbf{H} &= C_{\alpha} - \sum^{m}_{i=1} (c')^i*C_i \\
\sum^{N}_{j=1} [r_j*H_j] &= C_{\alpha} - \sum^{m}_{i=1} (c')^i*C_i \\
\sum^{N}_{j=1} [(\alpha_j - \sum^{m}_{i=1} c^i*v_{i,j})*H_j] &= C_{\alpha} - \sum^{m}_{i=1} (c')^i*C_i \\
(\sum^{N}_{j=1} \alpha_j*H_j) - \sum^{N}_{j=1} [(\sum^{m}_{i=1} c^i*v_{i,j})*H_j] &= C_{\alpha} - \sum^{m}_{i=1} (c')^i*C_i \\
C_{\alpha} - \sum^{m}_{i=1} c^i*[\sum^{N}_{j=1} v_{i,j}*H_j] &= C_{\alpha} - \sum^{m}_{i=1} (c')^i*C_i \\
C_{\alpha} - \sum^{m}_{i=1} c^i*C_i &= C_{\alpha} - \sum^{m}_{i=1} (c')^i*C_i \\\end{aligned}$$

Verifiers can be confident that provers know all elements of
$\boldsymbol{V}$ (except with negligible probability) thanks to a
confluence of features in this proof (combined with the logic from basic
Schnorr Signatures, explained in Section
[\[sec:schnorr-fiat-shamir\]](#sec:schnorr-fiat-shamir){reference-type="ref"
reference="sec:schnorr-fiat-shamir"}).

#### Justification of Features {#justification-of-features .unnumbered}

1.  If we do not use $\boldsymbol{H}$ or powers of $c$, and the response
    was instead
    $r = \sum \boldsymbol{\alpha} + c* \sum_{i=1}^{m} (\sum_{j=1}^{N} v_{i,j})$,
    then provers have only demonstrated they know the sum of all vector
    elements (at most). Or, in other words, just the discrete logarithm
    of $K = \sum_{i=1}^{m} C_i$ as in a normal Schnorr signature.

2.  Adding in $\boldsymbol{H}$ makes
    $r_j = \alpha_j +  c* \sum_{i=1}^{m} v_{i,j}$, which ensures provers
    must at least know the sum at each vector index $j$. While there may
    exist many other $\boldsymbol{r'}$ vectors that produce
    $R = \boldsymbol{r'} \bullet \boldsymbol{H} = r'_1*\lambda_1*G + r'_2*\lambda_2*G + ...$,
    it is very difficult to find any of them using just the sum of all
    elements (step 1) without knowing $\boldsymbol{\lambda}$ (which we
    assume to be unknown).[^3]

3.  Including powers of $c$ turns each response element $r_j$ into a
    polynomial function of $c$,
    $r_j(c) = \alpha_j + v_{1,j}*c + v_{2,j}*c^2 + ... + v_{m,j}*c^m$.
    Now, given $c$, there are many combinations of
    ($\alpha'_j, v'_{1,j}, ..., v'_{m,j}$) that will produce $r_j$, but
    the probability of guessing one is negligible since $r_j$ is itself
    unknown (and can be anything between 1 and $l$ \[$l$ is the elliptic
    curve subgroup\]). Even if the sum at each vector index is known
    (step 2), guessing a useful factorization becomes increasingly
    difficult as the size of $\boldsymbol{V}$ rises (usually the only
    one that works will be the actual elements of $\boldsymbol{V}$).
    Moreover, $c$ is unknown in advance so provers can't report a random
    $r_j$ (recall Section
    [\[sec:schnorr-fiat-shamir\]](#sec:schnorr-fiat-shamir){reference-type="ref"
    reference="sec:schnorr-fiat-shamir"}). This means provers must know
    all elements of $\boldsymbol{V}$.[^4]

## Inner Product Proof

Suppose we have two vectors $\boldsymbol{v}$ and $\boldsymbol{z}$, each
with $N$ elements. Their inner product is
$s = \boldsymbol{v} \bullet \boldsymbol{z}$, we have their commitments
$[C_s = x_s G + s H_1, C_v = (x_v, \boldsymbol{v}) \bullet (G,\boldsymbol{H}), C_z = (x_z, \boldsymbol{z}) \bullet (G,\boldsymbol{H})]$[^5],
and we want to prove the inner product equation holds (and that we know
all the elements) without revealing any information (aside from N) about
$(s, \boldsymbol{v}, \boldsymbol{z})$. In other words, prove the value
in $C_s$ is the inner product of the vectors, size N, in $C_v$ and
$C_z$. Note that now we include blinding factors $x_s$, $x_v$, and
$x_z$, which are not strictly part of the vectors being considered. This
concept will be useful in later sections, where it is important to hide
the original values with a random mask.

Basically, we do two vector knowledge proofs (Section
[1.1](#sec:vectorzkproof){reference-type="ref"
reference="sec:vectorzkproof"}) for $\boldsymbol{v}$ and
$\boldsymbol{z}$, and an extra bit for the inner product.

#### Non-interactive proof {#non-interactive-proof-1 .unnumbered}

1.  Generate two vectors (size N) and four integers
    $(\alpha_{v,0}, \boldsymbol{\alpha_v}, \alpha_{z,0}, \boldsymbol{\alpha_z}, \alpha_{s,0}, \alpha_{s,1}) \in_R \mathbb{Z}_l$,
    and compute $$\begin{aligned}
        C_{\alpha}^{v} &= (\alpha_{v,0},\boldsymbol{\alpha_v}) \bullet (G,\textbf{H}) \\
        C_{\alpha}^{z} &= (\alpha_{z,0}, \boldsymbol{\alpha_z}) \bullet (G,\textbf{H}) \\
        C_{\alpha}^{s,0} &= \alpha_{s,0}*G + (\boldsymbol{\alpha_v} \bullet \boldsymbol{\alpha_z})*H_1 \\
        C_{\alpha}^{s,1} &= \alpha_{s,1}*G + (\boldsymbol{v} \bullet \boldsymbol{\alpha_z} + \boldsymbol{z} \bullet \boldsymbol{\alpha_v})*H_1
        \end{aligned}$$

2.  Calculate the *challenge*
    $c = \mathcal{H}(...,C_{\alpha}^{v},C_{\alpha}^{z},C_{\alpha}^{s,0},C_{\alpha}^{s,1})$.

3.  Define the *response*, $\boldsymbol{r}$, containing vectors (size N)
    $\boldsymbol{r_v}, \boldsymbol{r_z}$, with $r_{v,0}, r_{z,0}$ for
    the vectors' blinding factors, and $r_s$ for the inner product
    blinding factor $$\begin{aligned}
        r_{v,0} &= \alpha_{v,0} - c*x_v \\
        r_{z,0} &= \alpha_{z,0} - c*x_z \\
        r_{v,j} &= \alpha_{v,j} - c*v_j \\
        r_{z,j} &= \alpha_{z,j} - c*z_j \\
        r_s &= \alpha_{s,0} + c*\alpha_{s,1} + c^2*x_s 
        \end{aligned}$$

4.  Publish the proof
    $(c, \boldsymbol{r}, C^{s,0}_{\alpha}, C^{s,1}_{\alpha})$.

#### Verification {#verification-1 .unnumbered}

1.  Calculate the challenge:
    $$c' = \mathcal{H}(...,[(r_{v,0},\boldsymbol{r_v}) \bullet (G,\textbf{H}) + c*C_v],[(r_{z,0},\boldsymbol{r_z}) \bullet (G,\textbf{H}) + c*C_z],[C^{s,0}_{\alpha}],[C^{s,1}_{\alpha}])$$

2.  Compute[^6] $$\begin{aligned}
        %R_v &= (r_{v,0},\boldsymbol{r_v}) \bullet \textbf{H} \\
        %R'_v &= C_{\alpha}^{v} + c'*C_v \\
        %R_z &= (r_{z,0},\boldsymbol{r_z}) \bullet \textbf{H} \\
        %R'_z &= C_{\alpha}^{z} + c'*C_z \\
        R_s &= r_s*G + (\boldsymbol{r_v} \bullet \boldsymbol{r_z})*H_1 \\
        R'_s &= C_{\alpha}^{s,0} + c'*C_{\alpha}^{s,1} + c'^2*C_s
        \end{aligned}$$

3.  If $c = c'$, and $R_s = R'_s$, then the prover must know
    $\boldsymbol{v}, \boldsymbol{z}$, and $s$, and the inner product
    $s = \boldsymbol{v} \bullet \boldsymbol{z}$ must hold (except with
    negligible probability).

#### Why it works (inner product component) {#why-it-works-inner-product-component .unnumbered}

$$\begin{aligned}
r_s*G + (\boldsymbol{r_v} \bullet \boldsymbol{r_z})*H_1 &= C_{\alpha}^{s,0} + c*C_{\alpha}^{s,1} + c^2*C_s \\
(\alpha_{s,0} + c \alpha_{s,1} + c^2 x_s)*G + (\boldsymbol{\alpha_v} \bullet \boldsymbol{\alpha_z} + c[\boldsymbol{v} \bullet \boldsymbol{\alpha_z} + \boldsymbol{z} \bullet \boldsymbol{\alpha_v}] + c^2 [\boldsymbol{v} \bullet \boldsymbol{z}])*H_1 &= C_{\alpha}^{s,0} + c*C_{\alpha}^{s,1} + c^2*C_s \\
C_{\alpha}^{s,0} + c*C_{\alpha}^{s,1} + c^2 (x_s*G + [\boldsymbol{v} \bullet \boldsymbol{z}]*H_1) &= C_{\alpha}^{s,0} + c*C_{\alpha}^{s,1} + c^2*C_s \\
c^2 (x_s*G + [\boldsymbol{v} \bullet \boldsymbol{z}]*H_1) &= c^2(x_s*G + s*H_1) \\
\boldsymbol{v} \bullet \boldsymbol{z} &= s\end{aligned}$$

Responses $\boldsymbol{r_v}$ and $\boldsymbol{r_z}$ prove knowledge of
vectors $\boldsymbol{v}$ and $\boldsymbol{z}$, so using them in
$R_s \stackrel{?}{=} R'_s$ proves the inner product holds. Readers can
explore the algebraic logic to confirm this for themselves.

## Condensed Vector Knowledge Proof {#sec:condensedvectorproof}

Our original vector knowledge proof was $(c, \boldsymbol{r})$, where the
proof size was linear with vector dimension. Given $N = 500$ (and
$m = 1$), the proof will take up $(1 + 500)*32 = 16032$ bytes. We can
condense the proof size with an approach exposed by Bootle et. al.
[@bootle-efficient-zkcircuits]. It will be logarithmic with vector
dimension (proof size $\approx 6*log_2(N)$, so for N = 500 proof size
around 54\*32 = 1728 bytes).

### Non-interactive proof {#non-interactive-proof-2 .unnumbered}

1.  With the intent of minimizing proof size (optimizing verification
    time is more complex), factor $N$ into $q$ prime numbers ordered
    largest to smallest. If $N = 500$,
    $\boldsymbol{f} = \langle 500, 5, 5, 5, 2, 2 \rangle$ and indexed
    $0$ to $q = 5$ (0term is the original N).

2.  For $i = 1$ to $q$ (index 0 corresponds to original vectors),

    1.  Chunk $\boldsymbol{v}^{i-1}$ and $\boldsymbol{G}^{i-1}$ into
        smaller vectors size $f[i]$
        $$\langle v^{i-1}[1], ..., v^{i-1}[f[i-1]] \rangle \xrightarrow{} \langle \langle v^{i-1}[1],...,v^{i-1}[f[i] \rangle,\langle \rangle,...,\langle v^{i-1}[f[i-1] - f[i] ],..., v^{i-1}[f[i-1]\rangle \rangle$$

    $$\begin{pmatrix}
            1 & 2 & 3 \\
            4 & 5 & 6
        \end{pmatrix}$$

### Verification {#verification-2 .unnumbered}

[^1]: The inner product (a.k.a. dot product) between vectors
    $\boldsymbol{v} = \langle 1, 2, 3 \rangle$ and
    $\boldsymbol{z} = \langle 4, 5, 6 \rangle$ is
    $\boldsymbol{v} \bullet \boldsymbol{z} = 1*4 + 2*5 + 3*6 = 32$.

[^2]: We explicitly do domain separation here with $T_{vec}$, and key
    prefixing with $\boldsymbol{V}$. For the rest of the chapter it is
    implied with ellipses (\...). Those ellipses could also include a
    message $\mathfrak{m}$ to make the proof a signature.

[^3]: Even if two or more vector indexes have the same sum
    ($\sum_{i=1}^{m} v_{i,a} = \sum_{i=1}^{m} v_{i,b} = k$), $k$ will
    not be revealed since in the equation pair $r_a = \alpha_a + c*k$
    and $r_b = \alpha_b + c*k$ there are three unknowns ($\alpha_a$,
    $\alpha_b$, and $k$), and each additional equation
    $r_q = \alpha_q + c*k$ adds another unknown ($\alpha_q$).

[^4]: A person with partial knowledge of $\boldsymbol{V}$ can increase
    his chances of faking the proof (by only a negligible amount in most
    cases). For an extreme example, if he knows all elements of
    $\boldsymbol{V}$ except one, he knows all commitments $C_j$ and
    their blinding factors, and he knows the missing element is in the
    range ($q$ to $p$) where ($p - q < l$), then his chances of guessing
    that element (and checking by computing $C'_j$) are higher than
    solving the discrete logarithm problem via guess and check. Though
    in this case he ultimately knows all elements of $\boldsymbol{V}$
    anyway. This logic extends to other partial-knowledge scenarios.

[^5]: Our notation $(x_v, \boldsymbol{v}) \bullet (G,\boldsymbol{H})$
    here means blinding factor $x_v$ is appended to the front of
    $\boldsymbol{v}$ for the inner product, and likewise with generator
    $G$.

[^6]: Since $C^{s,0}_{\alpha}$ and $C^{s,1}_{\alpha}$ are tied together,
    it isn't possible (within our knowledge) to move $R_s$ into the
    challenge computation.
