import asyncio
from services.ai_service import generate_mcq_with_ai

text = """
Identify the incorrect one from the following
1. Nuclear Protocol Treaty (NPT) - 1978
2. Comprehensive Nuclear Test Ban Treaty (CTBT) - 1996
3. Strategic Arms Reduction Treaty - I (START-I) - 1991
4. Limited Nuclear Test Ban Treaty (NTBT) - 1963
Options :
1. ✔ 1
2. ✖ 2
3. ✖ 3
4. ✖ 4
"""

async def main():
    try:
        res = await generate_mcq_with_ai(text)
        print("SUCCESS:", res)
    except Exception as e:
        print("ERROR:", str(e))

if __name__ == "__main__":
    asyncio.run(main())
