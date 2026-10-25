// Simulador de ritmo del juego. Lee los números reales de src/shared/Config (Balance, Eggs, Dragons) y mide cuánto tarda
// un jugador en llegar a cada hito. No es el juego: modela una rutina simple (entrenar, planear, abrir huevos, renacer)
// con supuestos sobre el vuelo que hay que revisar cuando el mapa de Isaac exista.
//
// Uso:  node tools/balance/simulate.mjs [horas]

import fs from "node:fs";

const configDir = new URL("../../src/shared/Config/", import.meta.url);
const read = (name) => fs.readFileSync(new URL(name, configDir), "utf8");

// --- Lectura de la configuración real -------------------------------------------------------------------------------
const B = {};
for (const m of read("Balance.luau").matchAll(/^\s*([A-Z_0-9]+) = ([0-9_.\s*+\/-]+),/gm)) {
	B[m[1]] = Function(`"use strict"; return (${m[2].replace(/_/g, "")});`)();
}

const eggsSrc = read("Eggs.luau");
const WEIGHTS = [...eggsSrc.matchAll(/rarity = "(\w+)", weight = (\d+)/g)].map((m) => ({ rarity: m[1], weight: Number(m[2]) }));
const EGGS = [...eggsSrc.matchAll(/id = "(\w+)", name = "[^"]+", price = (\d+)(?:, luck = ([\d.]+))?/g)].map((m) => ({
	id: m[1],
	price: Number(m[2]),
	luck: m[3] ? Number(m[3]) : 1,
}));
const DRAGONS = [
	...read("Dragons.luau").matchAll(
		/id = "(\w+)",\s*name = "[^"]+",\s*rarity = "(\w+)",\s*glideBonus = ([\d.]+),\s*coinsPerSecond = ([\d.]+)/g,
	),
].map((m) => ({ id: m[1], rarity: m[2], glide: Number(m[3]), cps: Number(m[4]) }));

// Valores de prueba por línea de comandos, sin tocar los archivos de Config:
//   --set NEST_SLOTS=12 --set COINS_PER_STUD=0.15 --eggs "Basic:50:1,Gilded:1500:2,Mythic:40000:4"
const args = process.argv.slice(2);
const positional = [];
for (let i = 0; i < args.length; i++) {
	if (args[i] === "--set") {
		const [key, value] = args[++i].split("=");
		B[key] = Number(value);
	} else if (args[i] === "--cps") {
		const factor = Number(args[++i]); // prueba: todos los dragones pagan este factor de lo actual
		for (const d of DRAGONS) d.cps *= factor;
	} else if (args[i] === "--eggs") {
		EGGS.length = 0;
		for (const part of args[++i].split(",")) {
			const [id, price, luck] = part.split(":");
			EGGS.push({ id, price: Number(price), luck: Number(luck ?? 1) });
		}
	} else {
		positional.push(args[i]);
	}
}

const MAX_EGGS = 2000; // tope de seguridad del simulador
const SAVE_SECONDS = 90; // el jugador simulado ahorra para el huevo que podría pagar con esta cantidad de segundos de ingresos
const EGGS_BY_PRICE = [...EGGS].sort((a, b) => a.price - b.price);
const DRAGON_BY_ID = new Map(DRAGONS.map((d) => [d.id, d]));
const DRAGONS_BY_RARITY = Object.fromEntries(WEIGHTS.map((w) => [w.rarity, DRAGONS.filter((d) => d.rarity === w.rarity)]));

// --- Utilidades -------------------------------------------------------------------------------------------------------
function rng(seed) {
	let a = seed >>> 0;
	return () => {
		a = (a + 0x6d2b79f5) >>> 0;
		let t = a;
		t = Math.imul(t ^ (t >>> 15), t | 1);
		t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
		return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
	};
}

function rollRarity(random, luck) {
	let total = 0;
	WEIGHTS.forEach((w, i) => (total += i === 0 ? w.weight : w.weight * luck));
	let roll = random() * total;
	for (let i = 0; i < WEIGHTS.length; i++) {
		roll -= i === 0 ? WEIGHTS[i].weight : WEIGHTS[i].weight * luck;
		if (roll <= 0) return WEIGHTS[i].rarity;
	}
	return WEIGHTS[WEIGHTS.length - 1].rarity;
}

const median = (xs) => {
	const s = xs.filter((x) => x !== null).sort((a, b) => a - b);
	return s.length ? s[Math.floor(s.length / 2)] : null;
};
const fmtTime = (s) => {
	if (s === null || s === undefined) return "   nunca";
	const m = Math.floor(s / 60);
	return `${String(m).padStart(3)}m${String(Math.floor(s % 60)).padStart(2, "0")}s`;
};

// --- Un jugador -------------------------------------------------------------------------------------------------------
// profile: clicks (por segundo), realized (fracción del tope de distancia que logra planeando), trainChunk (segundos entre vuelos),
// flightOverhead (segundos fijos por vuelo: caminar, subir, lanzarse), glideSpeed (studs por segundo)
function simulate(profile, seconds, seed) {
	const random = rng(seed);
	let power = 0;
	let coins = 0;
	let rebirths = 0;
	let eggs = 0;
	const owned = {};
	let equipped = [];
	const milestones = {};
	const mark = (name, t) => {
		if (milestones[name] === undefined) milestones[name] = t;
	};
	const samples = {};

	const slots = B.BASE_DRAGON_SLOTS;
	const clickRate = Math.min(profile.clicks, 1 / B.TRAIN_COOLDOWN);
	const rebirthCost = () => Math.floor(B.REBIRTH_BASE_POWER * B.REBIRTH_POWER_GROWTH ** rebirths);
	// Se recalculan solo cuando cambia el inventario (al abrir un huevo), no cada segundo.
	let glideCache = 1;
	let nestCache = 0;
	const glideMult = () => glideCache;
	const nestRate = () => nestCache;
	const reequip = () => {
		const pool = [];
		for (const [id, count] of Object.entries(owned)) for (let i = 0; i < count; i++) pool.push(id);
		pool.sort((a, b) => DRAGON_BY_ID.get(b).glide - DRAGON_BY_ID.get(a).glide);
		equipped = pool.slice(0, slots);

		glideCache = 1 + equipped.reduce((sum, id) => sum + DRAGON_BY_ID.get(id).glide, 0);
		const equippedCount = {};
		for (const id of equipped) equippedCount[id] = (equippedCount[id] ?? 0) + 1;
		// Los que descansan en el nido; si hay un tope de espacios, solo pagan los mejores.
		const resting = [];
		for (const [id, count] of Object.entries(owned)) {
			const n = count - (equippedCount[id] ?? 0);
			for (let i = 0; i < n; i++) resting.push(DRAGON_BY_ID.get(id).cps);
		}
		resting.sort((a, b) => b - a);
		nestCache = resting.slice(0, B.NEST_SLOTS ?? Infinity).reduce((a, b) => a + b, 0);
	};

	let mode = "train";
	let left = profile.trainChunk;
	let pending = 0;
	let lastCoins = 0;
	let spent = 0;
	let incomeEma = 0;

	for (let t = 1; t <= seconds; t++) {
		coins += nestRate();

		if (mode === "train") {
			power += clickRate * B.TRAIN_GAIN * (1 + B.REBIRTH_BONUS * rebirths);
			left--;
			if (left <= 0) {
				const distance = power * B.MAX_GLIDE_STUDS_PER_POWER * glideMult() * profile.realized;
				pending = Math.floor(distance * B.COINS_PER_STUD);
				left = Math.max(Math.ceil(profile.flightOverhead + distance / profile.glideSpeed), B.MIN_GLIDE_INTERVAL);
				mode = "fly";
			}
		} else {
			left--;
			if (left <= 0) {
				coins += pending;
				mode = "train";
				left = profile.trainChunk;
			}
		}

		// Ahorra para el huevo más caro que podría comprar con ~SAVE_SECONDS segundos de ingresos (al menos el más barato).
		const income = coins - lastCoins + spent;
		lastCoins = coins;
		spent = 0;
		incomeEma += (income - incomeEma) / 60;
		// El precio sube con los huevos ya abiertos (Balance.EGG_PRICE_STEP; 0 = precio fijo).
		const priceOf = (e) => Math.floor(e.price * (1 + (B.EGG_PRICE_STEP ?? 0) * eggs));
		const horizon = Math.max(incomeEma * SAVE_SECONDS, priceOf(EGGS_BY_PRICE[0]));
		const target = [...EGGS_BY_PRICE].reverse().find((e) => priceOf(e) <= horizon) ?? EGGS_BY_PRICE[0];

		for (;;) {
			const price = priceOf(target);
			const affordable = coins >= price ? target : null;
			if (!affordable) break;
			coins -= price;
			spent += price;
			const rarity = rollRarity(random, affordable.luck);
			const pool = DRAGONS_BY_RARITY[rarity];
			const dragon = pool[Math.floor(random() * pool.length)];
			owned[dragon.id] = (owned[dragon.id] ?? 0) + 1;
			eggs++;
			reequip();
			mark(`huevo ${eggs}`, t);
			mark(`primer ${rarity}`, t);
		}

		// Seguridad: si la economía se dispara, se corta aquí (y eso ya es un resultado: hay inflación).
		if (eggs >= MAX_EGGS) {
			mark(`huevo ${MAX_EGGS}`, t);
			break;
		}

		if (power >= rebirthCost()) {
			power = 0;
			rebirths++;
			mark(`renacer ${rebirths}`, t);
		}

		for (const minute of [5, 10, 30, 60, 120]) {
			if (t === minute * 60) {
				samples[minute] = { power, rebirths, eggs, nest: nestRate(), glide: glideMult(), dragons: Object.values(owned).reduce((a, b) => a + b, 0) };
			}
		}
	}
	return { milestones, samples, nestFinal: nestRate() };
}

// --- Informe ----------------------------------------------------------------------------------------------------------
const hours = Number(positional[0] ?? 2);
const PROFILES = {
	activo: { clicks: 4.5, realized: 0.7, trainChunk: 30, flightOverhead: 15, glideSpeed: 30 },
	casual: { clicks: 2, realized: 0.5, trainChunk: 45, flightOverhead: 20, glideSpeed: 30 },
};
const RUNS = 200;

console.log(`Configuración leída: ${EGGS.length} huevo(s), ${DRAGONS.length} dragones, precio base ${EGGS[0]?.price}, ${hours} h simuladas, ${RUNS} jugadores por perfil.\n`);

for (const [name, profile] of Object.entries(PROFILES)) {
	const results = Array.from({ length: RUNS }, (_, i) => simulate(profile, hours * 3600, 1000 + i));
	console.log(`=== Jugador ${name} (${profile.clicks} clics/s, logra ${Math.round(profile.realized * 100)} % del tope de distancia) ===`);

	const keys = ["huevo 1", "huevo 5", "huevo 10", "huevo 25", "huevo 50", "huevo 100", "huevo 500", `huevo ${MAX_EGGS}`, "primer Uncommon", "primer Rare", "primer Epic", "primer Legendary", "renacer 1", "renacer 2", "renacer 3", "renacer 5"];
	console.log("Hito (mediana de los jugadores)            tiempo   ¿cuántos lo logran?");
	for (const key of keys) {
		const times = results.map((r) => r.milestones[key] ?? null);
		const reached = times.filter((x) => x !== null).length;
		console.log(`  ${key.padEnd(30)} ${fmtTime(median(times))}   ${Math.round((reached / RUNS) * 100)} %`);
	}

	console.log("Estado a los…        poder  renacimientos  huevos  dragones  nido (monedas/s)  planeo");
	for (const minute of [5, 10, 30, 60, 120]) {
		if (minute * 60 > hours * 3600) continue;
		const at = results.map((r) => r.samples[minute]).filter(Boolean);
		if (at.length === 0) {
			console.log(`  ${String(minute).padStart(3)} min        (todos pasaron de ${MAX_EGGS} huevos antes de esta marca)`);
			continue;
		}
		const med = (f) => median(at.map(f));
		console.log(
			`  ${String(minute).padStart(3)} min        ${String(Math.round(med((s) => s.power))).padStart(6)}  ${String(med((s) => s.rebirths)).padStart(13)}  ${String(med((s) => s.eggs)).padStart(6)}  ${String(med((s) => s.dragons)).padStart(8)}  ${med((s) => s.nest).toFixed(2).padStart(16)}  x${med((s) => s.glide).toFixed(2)}`,
		);
	}
	const nest60 = median(results.map((r) => r.samples[60]?.nest ?? null));
	const exploded = results.filter((r) => r.milestones[`huevo ${MAX_EGGS}`] !== undefined).length;
	console.log(`  Jugadores que llegan a ${MAX_EGGS} huevos dentro de ${hours} h: ${Math.round((exploded / RUNS) * 100)} %`);
	if (nest60 !== null) {
		const offline = Math.floor(nest60 * B.OFFLINE_MAX_SECONDS * B.OFFLINE_EFFICIENCY);
		console.log(`  Si se va 8 h tras la hora 1: gana ~${offline} monedas sin conexión (${(offline / (EGGS[0]?.price ?? 1)).toFixed(1)} huevos básicos).`);
	}
	console.log("");
}
